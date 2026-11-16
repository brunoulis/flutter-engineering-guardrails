import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;

import 'audit_file.dart';
import 'finding.dart';
import 'project_index.dart';
import 'project_rules.dart';
import 'slop_score.dart';

/// Directory names skipped anywhere in the tree.
const _excludedDirs = {
  '.git', '.dart_tool', '.fvm', '.idea', 'build', 'coverage', //
  'generated', 'gen', 'node_modules', 'Pods',
};

/// Platform folders, skipped only directly under the audit root.
const _platformDirs = {'android', 'ios', 'linux', 'macos', 'web', 'windows'};

const _generatedSuffixes = [
  '.g.dart', '.freezed.dart', '.gr.dart', '.chopper.dart', '.mocks.dart', //
  '.gen.dart', '.reflectable.dart',
];

const _maxFileBytes = 2000000;

bool isGenerated(String path) {
  final name = p.basename(path);
  return _generatedSuffixes.any(name.endsWith) ||
      name.startsWith('flutter_gen');
}

final class ProjectReport {
  ProjectReport({
    required this.root,
    required this.scopes,
    required this.scannedFiles,
    required this.scannedLines,
    required this.findings,
    required this.skipped,
    required this.parseErrors,
    required this.resolution,
    this.slop,
  });

  final String root;
  final List<String> scopes;
  final int scannedFiles;
  final int scannedLines;
  final List<Finding> findings;
  final List<String> skipped;

  /// Relative path → syntax errors (the file was still audited).
  final Map<String, List<String>> parseErrors;

  /// `resolved` (analyzer type resolution) or `syntax-only (reason)`; both
  /// also use the cross-file class index.
  final String resolution;

  /// Present only with `--score`.
  final SlopReport? slop;
}

/// Audits every non-generated `.dart` file under [scopeDirs] (absolute,
/// already validated to be inside [root]). Read-only; symlinks are not
/// followed. With [resolve], files are resolved when the package's
/// dependencies are prepared (`.dart_tool/package_config.json`); otherwise, or
/// if resolution fails, the audit falls back to syntax plus the class index.
Future<ProjectReport> auditProject(
  String root,
  List<String> scopeDirs, {
  int largeFileLines = 700,
  ProjectRules? rules,
  bool resolve = true,
  bool score = false,
}) async {
  final files = <String>{};
  for (final scope in scopeDirs) {
    final entity = FileSystemEntity.typeSync(scope, followLinks: false);
    if (entity == FileSystemEntityType.file) {
      if (scope.endsWith('.dart') && !isGenerated(scope)) files.add(scope);
    } else if (entity == FileSystemEntityType.directory) {
      _walk(root, Directory(scope), files);
    }
  }
  final sorted = files.toList()..sort();

  final indexed = indexDisposableSubtypes(_readAll(sorted));

  var resolution = 'syntax-only (resolution disabled)';
  AnalysisContextCollection? collection;
  if (resolve) {
    if (File(p.join(root, '.dart_tool', 'package_config.json')).existsSync()) {
      try {
        collection = AnalysisContextCollection(includedPaths: [root]);
        resolution = 'resolved';
      } on Object catch (e) {
        resolution = 'syntax-only (resolution failed: $e)';
      }
    } else {
      resolution =
          'syntax-only (no .dart_tool/package_config.json; run pub get)';
    }
  }

  final findings = <Finding>[];
  final skipped = <String>[];
  final parseErrors = <String, List<String>>{};
  final navigation = <String, ({String path, int line})>{};
  var scannedLines = 0;

  for (final file in sorted) {
    final rel = p.posix.joinAll(p.split(p.relative(file, from: root)));
    try {
      if (File(file).lengthSync() > _maxFileBytes) {
        skipped.add('$rel: larger than 2 MB');
        continue;
      }
      final content = File(file).readAsStringSync();
      ResolvedUnitResult? resolved;
      if (collection != null) {
        final result = await collection
            .contextFor(file)
            .currentSession
            .getResolvedUnit(file);
        if (result is ResolvedUnitResult) resolved = result;
      }
      final audit = auditSource(
        rel,
        content,
        largeFileLines: largeFileLines,
        resolved: resolved,
        indexedDisposables: indexed,
      );
      scannedLines += audit.lines;
      findings.addAll(audit.findings);
      if (rules != null) findings.addAll(rules.audit(rel, content));
      if (audit.parseErrors.isNotEmpty) parseErrors[rel] = audit.parseErrors;
      for (final MapEntry(key: style, value: line)
          in audit.navigationStyles.entries) {
        navigation.putIfAbsent(style, () => (path: rel, line: line));
      }
    } on FileSystemException catch (e) {
      skipped.add('$rel: ${e.message}');
    } on FormatException catch (e) {
      skipped.add('$rel: not valid UTF-8 (${e.message})');
    }
  }

  if (navigation.length > 1) {
    final names = (navigation.keys.toList()..sort()).join(', ');
    for (final MapEntry(key: style, value: at) in navigation.entries) {
      findings.add(
        Finding(
          rule: 'mixed-navigation-styles',
          priority: 'P2',
          path: at.path,
          line: at.line,
          title: 'Several navigation APIs in use: $names',
          evidence: 'first $style call at ${at.path}:${at.line}',
          check:
              'Confirm the coexistence is intentional and that route and '
              'deep-link tests cover it.',
        ),
      );
    }
  }

  await collection?.dispose();
  findings.sort(Finding.compare);
  return ProjectReport(
    root: root,
    scopes: [
      for (final s in scopeDirs)
        p.posix.joinAll(p.split(p.relative(s, from: root))),
    ],
    scannedFiles: sorted.length - skipped.length,
    scannedLines: scannedLines,
    findings: findings,
    skipped: skipped,
    parseErrors: parseErrors,
    resolution: resolution,
    slop: score ? computeSlop(root, sorted) : null,
  );
}

Iterable<String> _readAll(List<String> files) sync* {
  for (final file in files) {
    try {
      if (File(file).lengthSync() <= _maxFileBytes) {
        yield File(file).readAsStringSync();
      }
    } on Exception {
      continue; // reported by the main pass
    }
  }
}

void _walk(String root, Directory dir, Set<String> files) {
  for (final entity in dir.listSync(followLinks: false)) {
    final name = p.basename(entity.path);
    if (entity is Directory) {
      if (_excludedDirs.contains(name)) continue;
      if (p.equals(dir.path, root) && _platformDirs.contains(name)) continue;
      _walk(root, entity, files);
    } else if (entity is File &&
        name.endsWith('.dart') &&
        !isGenerated(entity.path)) {
      files.add(entity.path);
    }
  }
}
