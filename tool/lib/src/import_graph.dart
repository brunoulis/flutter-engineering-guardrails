import 'dart:io';
import 'dart:math';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'finding.dart';

/// Distinct project files one file may import before it is reported.
const fanOutLimit = 20;

/// File-level import graph of the audited files, plus findings for import
/// cycles and excessive fan-out. [sources] maps root-relative `/` paths to
/// contents. Syntactic: conditional imports are ignored, `part` files are
/// not merged into their library, and only edges between audited files count.
List<Finding> auditImportGraph(String root, Map<String, String> sources) {
  final pkg = _packageName(root);
  final edges = <String, List<({String to, int line})>>{};
  final barrels = <String>{};

  for (final MapEntry(key: rel, value: src) in sources.entries) {
    final parsed = parseString(content: src, throwIfDiagnostics: false);
    final out = edges[rel] = [];
    var allExports = true;
    var any = false;
    for (final d in parsed.unit.directives) {
      if (d is! NamespaceDirective) continue;
      any = true;
      if (d is ImportDirective) allExports = false;
      final target = _resolve(rel, d.uri.stringValue, pkg);
      if (target != null && target != rel && sources.containsKey(target)) {
        out.add((
          to: target,
          line: parsed.lineInfo.getLocation(d.offset).lineNumber,
        ));
      }
    }
    if (any && allExports) barrels.add(rel);
  }

  final findings = <Finding>[];

  for (final scc in _cycles(edges)) {
    final members = scc.toList()..sort();
    final first = members.first;
    final line = edges[first]!.firstWhere((e) => scc.contains(e.to)).line;
    final crossDir = members.map(p.posix.dirname).toSet().length > 1;
    final list = '${members.length} files: ${members.join(', ')}';
    findings.add(
      Finding(
        rule: 'import-cycle',
        // A cycle between siblings is often deliberate; one across
        // directories crosses a boundary.
        priority: crossDir ? 'P2' : 'P3',
        path: first,
        line: line,
        title:
            'Import cycle across directories'
            '${crossDir ? '' : ' (all in one directory)'}',
        evidence: list.substring(0, min(list.length, 140)),
        check:
            'Decide whether the cycle is intentional (siblings, a barrel '
            're-export); otherwise extract the shared piece or invert one '
            'dependency.',
        basis: 'import-graph',
      ),
    );
  }

  for (final MapEntry(key: rel, value: out) in edges.entries) {
    if (barrels.contains(rel)) continue;
    if (out.map((e) => e.to).toSet().length > fanOutLimit) {
      findings.add(
        Finding(
          rule: 'high-fan-out',
          priority: 'P3',
          path: rel,
          line: 1,
          title: 'File depends on many project files',
          evidence: 'imports more than $fanOutLimit project files',
          check: 'Check whether the file mixes several responsibilities.',
          basis: 'import-graph',
        ),
      );
    }
  }
  return findings;
}

String? _packageName(String root) {
  try {
    final yaml = loadYaml(
      File(p.join(root, 'pubspec.yaml')).readAsStringSync(),
    );
    return yaml is YamlMap ? yaml['name']?.toString() : null;
  } on Object {
    return null;
  }
}

String? _resolve(String from, String? uri, String? pkg) {
  if (uri == null || uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    final prefix = 'package:$pkg/';
    return pkg != null && uri.startsWith(prefix)
        ? 'lib/${uri.substring(prefix.length)}'
        : null;
  }
  if (uri.contains(':')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(from), uri));
}

/// Tarjan's strongly connected components with more than one node.
List<Set<String>> _cycles(Map<String, List<({String to, int line})>> edges) {
  final index = <String, int>{};
  final low = <String, int>{};
  final stack = <String>[];
  final onStack = <String>{};
  final result = <Set<String>>[];

  void visit(String v) {
    index[v] = low[v] = index.length;
    stack.add(v);
    onStack.add(v);
    for (final e in edges[v]!) {
      if (!index.containsKey(e.to)) {
        visit(e.to);
        low[v] = min(low[v]!, low[e.to]!);
      } else if (onStack.contains(e.to)) {
        low[v] = min(low[v]!, index[e.to]!);
      }
    }
    if (low[v] == index[v]) {
      final scc = <String>{};
      String w;
      do {
        w = stack.removeLast();
        onStack.remove(w);
        scc.add(w);
      } while (w != v);
      if (scc.length > 1) result.add(scc);
    }
  }

  for (final v in edges.keys.toList()..sort()) {
    if (!index.containsKey(v)) visit(v);
  }
  return result;
}
