import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Minimum normalized tokens for a body to count as a duplication candidate.
const _minCloneTokens = 60;

/// Cyclomatic complexity above which a function is reported.
const complexityLimit = 15;

const _uiBases = {'StatelessWidget', 'StatefulWidget', 'State'};
const _ioNames = {
  'Dio',
  'HttpClient',
  'SharedPreferences',
  'jsonDecode',
  'http',
};
const _uiInViewModel = {
  'BuildContext', 'Navigator', 'showDialog', 'ScaffoldMessenger', //
};
const _logicSuffixes = [
  'ViewModel',
  'Repository',
  'RepositoryImpl',
  'DataSource',
  'Service',
  'UseCase',
];
const _implicitDeps = {
  'flutter',
  'flutter_localizations',
  'flutter_web_plugins',
  'cupertino_icons',
};

/// One piece of evidence behind a grade.
final class SlopItem {
  const SlopItem(this.path, this.line, this.title);
  final String path;
  final int line;
  final String title;

  Map<String, Object> toJson() => {'path': path, 'line': line, 'title': title};
}

/// A dimension is `null`-graded (N/E) when the project gives no evidence to
/// measure it. Grades follow [gradeFor]; they are never summed.
final class SlopDimension {
  const SlopDimension(this.name, this.items, {this.note});
  final String name;

  /// `null` = not evaluated (nothing to measure).
  final List<SlopItem>? items;
  final String? note;

  int? get grade => items == null ? null : gradeFor(items!.length);
}

/// 3 = no evidence, 2 = 1-2 items, 1 = 3-9, 0 = 10+. Heuristic bands, not
/// benchmarks; they exist so a report can be compared with itself over time.
int gradeFor(int count) => count == 0
    ? 3
    : count <= 2
    ? 2
    : count < 10
    ? 1
    : 0;

final class SlopReport {
  const SlopReport(this.dimensions);
  final List<SlopDimension> dimensions;

  Map<String, Object?> toJson() => {
    'scale':
        '3 = no evidence ... 0 = 10+ items; null = not evaluated. Not summed.',
    'dimensions': {
      for (final d in dimensions)
        d.name: {
          'grade': d.grade,
          'evidence': [
            for (final i in d.items ?? const <SlopItem>[]) i.toJson(),
          ],
          if (d.note != null) 'note': d.note,
        },
    },
  };
}

/// Evidence-based slop signals over [files] (absolute paths under [root]).
/// Never scores file length, widget count or layer count by themselves.
SlopReport computeSlop(String root, List<String> files) {
  final clones = <String, List<SlopItem>>{};
  final complex = <SlopItem>[];
  final mixed = <SlopItem>[];
  final wrappers = <SlopItem>[];
  final logicFiles = <String, String>{}; // rel path under lib -> report path

  for (final file in files) {
    final rel = p.posix.joinAll(p.split(p.relative(file, from: root)));
    final String content;
    try {
      content = File(file).readAsStringSync();
    } on Exception {
      continue;
    }
    final parsed = parseString(content: content, throwIfDiagnostics: false);
    final lines = parsed.lineInfo;
    int lineOf(AstNode n) => lines.getLocation(n.offset).lineNumber;

    final scan = _SlopVisitor(lineOf);
    parsed.unit.accept(scan);
    for (final b in scan.bodies) {
      final key = _normalized(b.body);
      if (key != null) {
        clones
            .putIfAbsent(key, () => [])
            .add(SlopItem(rel, lineOf(b.owner), b.name));
      }
      final c = _complexity(b.body);
      // copyWith has one `??` per field: branches, but not real complexity.
      if (c > complexityLimit && b.name != 'copyWith') {
        complex.add(
          SlopItem(rel, lineOf(b.owner), '${b.name}: cyclomatic complexity $c'),
        );
      }
    }
    for (final m in scan.mixed) {
      mixed.add(SlopItem(rel, m.$1, m.$2));
    }
    for (final w in scan.wrappers) {
      wrappers.add(SlopItem(rel, w.$1, w.$2));
    }
    if (rel.startsWith('lib/') && scan.hasLogicClass) {
      logicFiles[rel.substring(4)] = rel;
    }
  }

  final duplicates = <SlopItem>[
    for (final group in clones.values)
      if (group.length > 1)
        for (final i in group)
          SlopItem(
            i.path,
            i.line,
            '${i.title}: same normalized body as ${group.length - 1} other(s), '
            'e.g. ${group.firstWhere((o) => o != i).path}:'
            '${group.firstWhere((o) => o != i).line}',
          ),
  ];

  return SlopReport([
    SlopDimension(
      'duplication',
      duplicates,
      note:
          'Bodies of >= $_minCloneTokens tokens equal after renaming '
          'identifiers (literals kept).',
    ),
    SlopDimension(
      'complexity',
      complex,
      note: 'Cyclomatic complexity > $complexityLimit per function.',
    ),
    SlopDimension(
      'mixed-responsibilities',
      mixed,
      note: 'Widgets doing I/O; view models touching BuildContext/navigation.',
    ),
    SlopDimension(
      'useless-layers',
      wrappers,
      note:
          'Classes whose every method forwards 1:1 to one field and that '
          'implement no contract. Layers the project mandates are not slop.',
    ),
    _unusedDependencies(root),
    _untestedLogic(root, logicFiles),
  ]);
}

SlopDimension _unusedDependencies(String root) {
  final pubspec = File(p.join(root, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return const SlopDimension('dependencies', null);
  final Object? yaml;
  try {
    yaml = loadYaml(pubspec.readAsStringSync());
  } on YamlException {
    return const SlopDimension(
      'dependencies',
      null,
      note: 'pubspec unreadable',
    );
  }
  final deps = yaml is YamlMap ? yaml['dependencies'] : null;
  if (deps is! YamlMap) return const SlopDimension('dependencies', null);

  final used = <String>{};
  final re = RegExp(r'''package:([a-z0-9_]+)/''');
  for (final dir in ['lib', 'bin', 'test', 'integration_test']) {
    final d = Directory(p.join(root, dir));
    if (!d.existsSync()) continue;
    for (final e in d.listSync(recursive: true, followLinks: false)) {
      if (e is File && e.path.endsWith('.dart')) {
        try {
          used.addAll(re.allMatches(e.readAsStringSync()).map((m) => m[1]!));
        } on Exception {
          continue;
        }
      }
    }
  }
  return SlopDimension(
    'dependencies',
    [
      for (final k in deps.keys.cast<String>())
        if (!_implicitDeps.contains(k) && !used.contains(k))
          SlopItem('pubspec.yaml', 0, '`$k` is never imported'),
    ],
    note:
        'Plugin-implementation or config-only packages (e.g. launcher icons) '
        'can be used without an import: verify each.',
  );
}

SlopDimension _untestedLogic(String root, Map<String, String> logicFiles) {
  if (logicFiles.isEmpty) return const SlopDimension('tests', null);
  final imported = <String>{};
  final names = <String>{};
  final re = RegExp(r'''import\s+['"]([^'"]+)['"]''');
  for (final dir in ['test', 'integration_test']) {
    final d = Directory(p.join(root, dir));
    if (!d.existsSync()) continue;
    for (final e in d.listSync(recursive: true, followLinks: false)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      names.add(p.basename(e.path));
      try {
        imported.addAll(
          re.allMatches(e.readAsStringSync()).map((m) => p.basename(m[1]!)),
        );
      } on Exception {
        continue;
      }
    }
  }
  return SlopDimension(
    'tests',
    [
      for (final MapEntry(key: lib, value: rel) in logicFiles.entries)
        if (!imported.contains(p.basename(lib)) &&
            !names.contains('${p.basenameWithoutExtension(lib)}_test.dart'))
          SlopItem(rel, 1, 'logic file not imported by any test'),
    ],
    note:
        'Matches by file name only: an import is not coverage. Run '
        '`flutter test --coverage` to confirm.',
  );
}

String? _normalized(FunctionBody body) {
  final out = <String>[];
  final end = body.endToken;
  for (Token? t = body.beginToken; t != null; t = t.next) {
    out.add(t.type == TokenType.IDENTIFIER ? 'I' : t.lexeme);
    if (t == end || t.isEof) break;
  }
  return out.length >= _minCloneTokens ? out.join(' ') : null;
}

int _complexity(FunctionBody body) {
  final v = _Complexity();
  body.accept(v);
  return v.count + 1;
}

final class _Complexity extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitIfStatement(IfStatement node) {
    count++;
    super.visitIfStatement(node);
  }

  @override
  void visitIfElement(IfElement node) {
    count++;
    super.visitIfElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    count++;
    super.visitForStatement(node);
  }

  @override
  void visitForElement(ForElement node) {
    count++;
    super.visitForElement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    count++;
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    count++;
    super.visitDoStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    count++;
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    count++;
    super.visitConditionalExpression(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    count += node.members.length;
    super.visitSwitchStatement(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    count += node.cases.length;
    super.visitSwitchExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final t = node.operator.type;
    if (t == TokenType.AMPERSAND_AMPERSAND ||
        t == TokenType.BAR_BAR ||
        t == TokenType.QUESTION_QUESTION) {
      count++;
    }
    super.visitBinaryExpression(node);
  }
}

typedef _Body = ({String name, AstNode owner, FunctionBody body});

final class _SlopVisitor extends RecursiveAstVisitor<void> {
  _SlopVisitor(this.lineOf);
  final int Function(AstNode) lineOf;

  final bodies = <_Body>[];
  final mixed = <(int, String)>[];
  final wrappers = <(int, String)>[];
  bool hasLogicClass = false;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    bodies.add((name: node.name.lexeme, owner: node, body: node.body));
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    bodies.add((
      name: node.name.lexeme,
      owner: node,
      body: node.functionExpression.body,
    ));
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.namePart.typeName.lexeme;
    final base = node.extendsClause?.superclass.name.lexeme ?? '';
    if (_logicSuffixes.any(name.endsWith)) hasLogicClass = true;

    final names = <String>{};
    node.accept(_Names(names));
    if (_uiBases.contains(base)) {
      final io = names.intersection(_ioNames);
      if (io.isNotEmpty) {
        mixed.add((
          lineOf(node),
          '$name (widget) uses ${io.join(', ')} directly',
        ));
      }
    } else if (base.endsWith('ViewModel') || base == 'ChangeNotifier') {
      final ui = names.intersection(_uiInViewModel);
      if (ui.isNotEmpty) {
        mixed.add((lineOf(node), '$name (view model) uses ${ui.join(', ')}'));
      }
    }

    final w = _wrapperTarget(node);
    if (w != null) {
      wrappers.add((lineOf(node), '$name forwards every method to `$w`'));
    }
    super.visitClassDeclaration(node);
  }
}

final class _Names extends RecursiveAstVisitor<void> {
  _Names(this.names);
  final Set<String> names;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

/// Field name when every method of [node] is `=> field.sameName(sameArgs)`,
/// there are at least 2 methods and the class implements no contract.
String? _wrapperTarget(ClassDeclaration node) {
  if (node.implementsClause != null) return null;
  final body = node.body;
  if (body is! BlockClassBody) return null;
  final methods = body.members.whereType<MethodDeclaration>().where(
    (m) => !m.isGetter && !m.isSetter && !m.isStatic,
  );
  if (methods.length < 2) return null;
  String? target;
  for (final m in methods) {
    final b = m.body;
    final Expression? e = switch (b) {
      ExpressionFunctionBody(:final expression) => expression,
      BlockFunctionBody(
        block: Block(statements: [ReturnStatement(:final expression)]),
      ) =>
        expression,
      _ => null,
    };
    if (e is! MethodInvocation ||
        e.methodName.name != m.name.lexeme ||
        e.target is! SimpleIdentifier) {
      return null;
    }
    final t = (e.target as SimpleIdentifier).name;
    if (target != null && target != t) return null;
    target = t;
  }
  return target;
}
