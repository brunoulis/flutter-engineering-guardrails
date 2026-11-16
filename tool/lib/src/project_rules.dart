import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:yaml/yaml.dart';

import 'finding.dart';

/// Architecture rules declared by the project in `.flutter-rails.yaml`
/// under `rules:`. Syntactic and name-based: leads, not proof.
///
///     rules:
///       viewmodel-base-class:      # classes named *<suffix> must extend <must-extend>
///         paths: [lib]             # optional glob prefixes (default: everywhere)
///         class-suffix: ViewModel
///         must-extend: BaseViewModel
///         exclude: [BaseViewModel] # class names exempt (the bases themselves)
///       forbidden-imports:
///         - paths: [lib/**/presentation]
///           imports: [package:http, package:dio]
///       forbidden-types:           # e.g. no BuildContext inside viewmodels
///         - class-suffix: ViewModel
///           types: [BuildContext]
final class ProjectRules {
  ProjectRules._(this._base, this._imports, this._types);

  final _BaseRule? _base;
  final List<_ImportRule> _imports;
  final List<_TypeRule> _types;

  /// Returns null when [yamlSource] has no `rules:` section. Throws
  /// [FormatException] when the section is malformed.
  static ProjectRules? parse(String yamlSource) {
    final Object? doc;
    try {
      doc = loadYaml(yamlSource);
    } on YamlException catch (e) {
      throw FormatException('.flutter-rails.yaml: ${e.message}');
    }
    if (doc is! YamlMap || doc['rules'] == null) return null;
    final rules = doc['rules'];
    if (rules is! YamlMap) {
      throw const FormatException('.flutter-rails.yaml: `rules` must be a map');
    }
    final base = rules['viewmodel-base-class'];
    return ProjectRules._(
      base == null ? null : _BaseRule.parse(_map(base, 'viewmodel-base-class')),
      [
        for (final e in _list(rules['forbidden-imports'], 'forbidden-imports'))
          _ImportRule.parse(_map(e, 'forbidden-imports')),
      ],
      [
        for (final e in _list(rules['forbidden-types'], 'forbidden-types'))
          _TypeRule.parse(_map(e, 'forbidden-types')),
      ],
    );
  }

  List<Finding> audit(String path, String content) {
    final base = _base != null && _base.appliesTo(path) ? _base : null;
    final imports = _imports.where((r) => r.appliesTo(path)).toList();
    final types = _types.where((r) => r.appliesTo(path)).toList();
    if (base == null && imports.isEmpty && types.isEmpty) return const [];

    final parsed = parseString(content: content, throwIfDiagnostics: false);
    final sourceLines = content.split('\n');
    final out = <Finding>[];

    void add(AstNode node, String rule, String title, String check) {
      final line = parsed.lineInfo.getLocation(node.offset).lineNumber;
      final text = sourceLines[line - 1].trim();
      out.add(
        Finding(
          rule: rule,
          priority: 'P2',
          path: path,
          line: line,
          title: title,
          evidence: text.length > 140 ? text.substring(0, 140) : text,
          check: check,
        ),
      );
    }

    for (final r in imports) {
      for (final d in parsed.unit.directives.whereType<ImportDirective>()) {
        final uri = d.uri.stringValue ?? '';
        if (r.imports.any(uri.startsWith)) {
          add(
            d,
            'project-forbidden-import',
            'Import `$uri` is forbidden here by .flutter-rails.yaml',
            'Move the access behind the repository/datasource boundary.',
          );
        }
      }
    }

    for (final c in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      final name = c.namePart.typeName.lexeme;
      if (base != null &&
          name.endsWith(base.suffix) &&
          !base.exclude.contains(name) &&
          c.extendsClause?.superclass.name.lexeme != base.mustExtend) {
        add(
          c,
          'project-viewmodel-base-class',
          '$name does not extend ${base.mustExtend}',
          'Confirm it reaches ${base.mustExtend} through another base class '
              '(this check looks at the direct `extends` only).',
        );
      }
      for (final r in types.where((r) => name.endsWith(r.suffix))) {
        final scan = _TypeScan(r.types);
        c.accept(scan);
        for (final hit in scan.hits) {
          add(
            hit,
            'project-forbidden-type',
            '$name uses ${hit.name.lexeme}, forbidden by .flutter-rails.yaml',
            'Keep this type in the view; pass plain values to the viewmodel.',
          );
        }
      }
    }
    return out;
  }
}

final class _TypeScan extends RecursiveAstVisitor<void> {
  _TypeScan(this.types);
  final Set<String> types;
  final hits = <NamedType>[];

  @override
  void visitNamedType(NamedType node) {
    if (types.contains(node.name.lexeme)) hits.add(node);
    super.visitNamedType(node);
  }
}

YamlMap _map(Object? v, String where) {
  if (v is YamlMap) return v;
  throw FormatException('.flutter-rails.yaml: `$where` entries must be maps');
}

List<Object?> _list(Object? v, String where) {
  if (v == null) return const [];
  if (v is YamlList) return v.toList();
  throw FormatException('.flutter-rails.yaml: `$where` must be a list');
}

List<String> _strings(Object? v, String key) {
  if (v == null) return const [];
  if (v is YamlList && v.every((e) => e is String)) {
    return v.cast<String>().toList();
  }
  throw FormatException(
    '.flutter-rails.yaml: `$key` must be a list of strings',
  );
}

String _string(Object? v, String key) {
  if (v is String && v.isNotEmpty) return v;
  throw FormatException('.flutter-rails.yaml: `$key` is required (string)');
}

/// `**` crosses directories, `*` does not; the glob matches a path prefix.
RegExp _glob(String g) {
  final b = StringBuffer('^');
  for (var i = 0; i < g.length; i++) {
    if (g.startsWith('**', i)) {
      b.write('.*');
      i++;
    } else if (g[i] == '*') {
      b.write('[^/]*');
    } else {
      b.write(RegExp.escape(g[i]));
    }
  }
  return RegExp(b.toString());
}

List<RegExp> _globs(YamlMap m) => [
  for (final g in _strings(m['paths'], 'paths')) _glob(g),
];

mixin _Scoped {
  List<RegExp> get globs;
  bool appliesTo(String path) =>
      globs.isEmpty || globs.any((g) => g.hasMatch(path));
}

final class _BaseRule with _Scoped {
  _BaseRule(this.globs, this.suffix, this.mustExtend, this.exclude);
  factory _BaseRule.parse(YamlMap m) => _BaseRule(
    _globs(m),
    _string(m['class-suffix'], 'class-suffix'),
    _string(m['must-extend'], 'must-extend'),
    _strings(m['exclude'], 'exclude').toSet(),
  );
  @override
  final List<RegExp> globs;
  final String suffix;
  final String mustExtend;
  final Set<String> exclude;
}

final class _ImportRule with _Scoped {
  _ImportRule(this.globs, this.imports);
  factory _ImportRule.parse(YamlMap m) =>
      _ImportRule(_globs(m), _strings(m['imports'], 'imports'));
  @override
  final List<RegExp> globs;
  final List<String> imports;
}

final class _TypeRule with _Scoped {
  _TypeRule(this.globs, this.suffix, this.types);
  factory _TypeRule.parse(YamlMap m) => _TypeRule(
    _globs(m),
    _string(m['class-suffix'], 'class-suffix'),
    _strings(m['types'], 'types').toSet(),
  );
  @override
  final List<RegExp> globs;
  final String suffix;
  final Set<String> types;
}
