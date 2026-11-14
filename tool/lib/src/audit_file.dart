import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'finding.dart';

/// Types whose instances must be disposed by the object that creates them.
/// Syntactic match on the class name: subclasses and aliases are not seen.
const disposableTypes = {
  'AnimationController',
  'CarouselController',
  'DraggableScrollableController',
  'FixedExtentScrollController',
  'FocusNode',
  'FocusScopeNode',
  'PageController',
  'ScrollController',
  'SearchController',
  'TabController',
  'TextEditingController',
  'TrackingScrollController',
  'TransformationController',
  'UndoHistoryController',
  'ValueNotifier',
  'WidgetStatesController',
};

/// Methods where a class releases what it owns.
const _releaseMethods = {'dispose', 'close', 'onClose'};

const _asyncBuilders = {'FutureBuilder', 'StreamBuilder'};
const _getxNavigation = {
  'to', 'toNamed', 'off', 'offNamed', 'offAll', 'offAllNamed', 'back', //
};
const _goRouterNavigation = {
  'go', 'goNamed', 'push', 'pushNamed', 'pushReplacement', //
  'pushReplacementNamed', 'replace', 'replaceNamed', 'pop', 'canPop',
};

final _ignoreForFile = RegExp(r'^\s*//\s*ignore_for_file\s*:');

/// Result of auditing one file.
final class FileAudit {
  FileAudit(this.findings, this.navigationStyles, this.parseErrors, this.lines);

  final List<Finding> findings;

  /// Navigation API family (`navigator`, `getx`, `go_router`) → first line.
  final Map<String, int> navigationStyles;

  /// Syntax errors as `line:column message`. The file is still audited.
  final List<String> parseErrors;
  final int lines;
}

/// Audits Dart [content] syntactically. [path] is only used for reporting.
FileAudit auditSource(String path, String content, {int largeFileLines = 700}) {
  final parsed = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
  );
  final lineInfo = parsed.lineInfo;
  final sourceLines = content.split('\n');
  final lines = content.endsWith('\n')
      ? sourceLines.length - 1
      : sourceLines.length;

  final collector = _Collector(path, content, lineInfo);
  parsed.unit.accept(collector);

  for (var i = 0; i < sourceLines.length; i++) {
    if (_ignoreForFile.hasMatch(sourceLines[i])) {
      collector.addAtLine(
        i + 1,
        rule: 'filewide-lint-suppression',
        priority: 'P3',
        title: 'File-wide lint suppression',
        check:
            'Justify each suppressed rule; narrow it to a line-level '
            '`// ignore:` where possible.',
      );
    }
  }
  if (lines > largeFileLines) {
    collector.addAtLine(
      1,
      rule: 'large-dart-file',
      priority: 'P3',
      title: 'File has $lines lines (threshold $largeFileLines)',
      check: 'Review cohesion and responsibilities; never split by size alone.',
    );
  }

  final errors = [
    for (final e in parsed.errors)
      () {
        final loc = lineInfo.getLocation(e.offset);
        return '${loc.lineNumber}:${loc.columnNumber} ${e.message}';
      }(),
  ];
  return FileAudit(collector.findings, collector.navigation, errors, lines);
}

final class _Collector extends RecursiveAstVisitor<void> {
  _Collector(this.path, this.content, this.lineInfo);

  final String path;
  final String content;
  final LineInfo lineInfo;
  final findings = <Finding>[];
  final navigation = <String, int>{};

  int _line(int offset) => lineInfo.getLocation(offset).lineNumber;

  void addAtLine(
    int line, {
    required String rule,
    required String priority,
    required String title,
    required String check,
  }) {
    final start = lineInfo.getOffsetOfLine(line - 1);
    final end = line < lineInfo.lineCount
        ? lineInfo.getOffsetOfLine(line)
        : content.length;
    var evidence = content.substring(start, end).trim();
    if (evidence.length > 140) evidence = evidence.substring(0, 140);
    findings.add(
      Finding(
        rule: rule,
        priority: priority,
        path: path,
        line: line,
        title: title,
        evidence: evidence,
        check: check,
      ),
    );
  }

  void _add(
    AstNode node, {
    required String rule,
    required String priority,
    required String title,
    required String check,
  }) => addAtLine(
    _line(node.offset),
    rule: rule,
    priority: priority,
    title: title,
    check: check,
  );

  // ---- class-level ownership: controllers and timers ----

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _auditOwnership(node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _auditOwnership(node);
    super.visitMixinDeclaration(node);
  }

  void _auditOwnership(AstNode owner) {
    final scan = _OwnershipScan()..run(owner);
    for (final MapEntry(key: name, value: created) in scan.owned.entries) {
      if (scan.released.contains(name)) continue;
      _add(
        created.node,
        rule: 'undisposed-controller',
        priority: 'P2',
        title:
            'No disposal found for field `$name` (${created.type}) '
            'created here',
        check:
            'Confirm the real owner: if this class created it, dispose it '
            'in dispose()/close(); if ownership is handed elsewhere, say where. '
            'App-lifetime objects (bindings, singletons) may never need it.',
      );
    }
  }

  // ---- expression-level rules ----

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final target = node.realTarget;

    if (name == 'setState' &&
        (target == null || target is ThisExpression) &&
        !node.isCascaded) {
      final first = node.argumentList.arguments.firstOrNull?.argumentExpression;
      if (first is FunctionExpression && first.body.isAsynchronous) {
        _add(
          node,
          rule: 'setstate-async-callback',
          priority: 'P1',
          title: 'setState() receives an async callback',
          check:
              'Await outside setState, check `mounted`, then update state '
              'synchronously (Flutter asserts on a Future-returning callback).',
        );
      }
    }

    if (name == 'periodic' &&
        target is SimpleIdentifier &&
        target.name == 'Timer') {
      _auditPeriodicTimer(node);
    }

    if (target is SimpleIdentifier) {
      final style = switch (target.name) {
        'Navigator' => 'navigator',
        'Get' when _getxNavigation.contains(name) => 'getx',
        'GoRouter' => 'go_router',
        'context' when _goRouterNavigation.contains(name) => 'go_router',
        _ => null,
      };
      if (style != null) {
        navigation.putIfAbsent(style, () => _line(node.offset));
      }
    }

    if (target == null && !node.isCascaded && _asyncBuilders.contains(name)) {
      _auditAsyncBuilder(node, node.argumentList);
    }
    _auditCreationInBuild(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_asyncBuilders.contains(node.constructorName.type.name.lexeme)) {
      _auditAsyncBuilder(node, node.argumentList);
    }
    _auditCreationInBuild(node);
    super.visitInstanceCreationExpression(node);
  }

  void _auditAsyncBuilder(Expression node, ArgumentList arguments) {
    if (!_insideBuild(node)) return;
    for (final arg in arguments.arguments) {
      if (arg is! NamedArgument) continue;
      final label = arg.name.lexeme;
      if (label != 'future' && label != 'stream') continue;
      final value = _unwrap(arg.argumentExpression);
      if (value is MethodInvocation ||
          value is FunctionExpressionInvocation ||
          value is InstanceCreationExpression) {
        _add(
          arg,
          rule: 'future-created-in-build',
          priority: 'P2',
          title:
              'The `$label:` of a ${label == 'future' ? 'FutureBuilder' : 'StreamBuilder'} '
              'contains a call inside build()',
          check:
              'Check whether this call returns a new future/stream or an '
              'existing cached value. If it starts new work per rebuild, '
              'store it with the owner and refresh when its inputs change.',
        );
      }
    }
  }

  void _auditCreationInBuild(Expression node) {
    final type = createdType(node);
    if (type == null || !disposableTypes.contains(type)) return;
    if (!_insideBuild(node)) return;
    AstNode? parent = node.parent;
    while (parent is CascadeExpression || parent is ParenthesizedExpression) {
      parent = parent!.parent;
    }
    if (parent is AssignmentExpression) {
      final name = refName(parent.leftHandSide);
      if (parent.operator.type == TokenType.QUESTION_QUESTION_EQ &&
          name != null &&
          _fieldsOfEnclosingType(node).contains(name)) {
        return; // a field can cache across builds; a local variable cannot
      }
      if (name != null && _disposedBefore(parent, name)) {
        return; // direct replacement after release in the same block
      }
    }
    _add(
      node,
      rule: 'controller-created-in-build',
      priority: 'P2',
      title: '$type is constructed inside build()',
      check:
          'Check repeated builds: replacing a field can lose the previous '
          'instance even if dispose() releases the last value. Reuse it, or '
          'verify replacement releases the old instance and preserves state.',
    );
  }

  void _auditPeriodicTimer(MethodInvocation node) {
    final parent = node.parent;
    String? holder;
    if (parent is VariableDeclaration && parent.initializer == node) {
      holder = parent.name.lexeme;
    } else if (parent is AssignmentExpression && parent.rightHandSide == node) {
      holder = refName(parent.leftHandSide);
    } else if (parent is ReturnStatement ||
        parent is ExpressionFunctionBody ||
        parent is ArgumentList ||
        parent is NamedArgument ||
        parent is ListLiteral ||
        parent is SetOrMapLiteral) {
      return; // handed to the caller or a collection that owns it
    }

    final AstNode scope =
        node.thisOrAncestorOfType<ClassDeclaration>() ??
        node.thisOrAncestorOfType<MixinDeclaration>() ??
        node.root;

    if (holder != null) {
      final scan = _OwnershipScan()..run(scope);
      if (scan.cancelled.contains(holder) || scan.released.contains(holder)) {
        return;
      }
      _add(
        node,
        rule: 'uncancelled-periodic-timer',
        priority: 'P2',
        title: 'No cancellation found for Timer.periodic stored in `$holder`',
        check: 'Cancel it in dispose()/close() or when its work is done.',
      );
      return;
    }

    // Result discarded: only the callback itself can stop the timer.
    final callback = node.argumentList.arguments.length > 1
        ? node.argumentList.arguments[1].argumentExpression
        : null;
    if (callback is FunctionExpression) {
      final param = callback.parameters?.parameters.firstOrNull?.name?.lexeme;
      if (param != null && param != '_') {
        final scan = _OwnershipScan()..run(callback.body);
        if (scan.cancelled.contains(param)) return;
      }
    }
    _add(
      node,
      rule: 'uncancelled-periodic-timer',
      priority: 'P2',
      title: 'Timer.periodic result is discarded; no self-cancellation found',
      check:
          'Keep the Timer and cancel it with its owner, or cancel it from '
          'the callback when done.',
    );
  }

  bool _insideBuild(AstNode node) =>
      node.thisOrAncestorOfType<MethodDeclaration>()?.name.lexeme == 'build';

  Set<String> _fieldsOfEnclosingType(AstNode node) {
    final AstNode? owner =
        node.thisOrAncestorOfType<ClassDeclaration>() ??
        node.thisOrAncestorOfType<MixinDeclaration>();
    if (owner == null) return const {};
    return (_OwnershipScan()..run(owner)).fields;
  }

  bool _disposedBefore(AstNode node, String name) {
    final statement = node.thisOrAncestorOfType<Statement>();
    final block = statement?.parent;
    if (block is! Block) return false;
    final index = block.statements.indexOf(statement!);
    if (index < 1) return false;
    final previous = block.statements[index - 1];
    if (previous is! ExpressionStatement) return false;
    final expression = previous.expression;
    return expression is MethodInvocation &&
        expression.methodName.name == 'dispose' &&
        refName(expression.realTarget) == name;
  }
}

final class _Created {
  _Created(this.type, this.node);
  final String type;
  final AstNode node;
}

/// Collects, within one class/mixin (or any subtree):
/// - [owned]: fields that the scope itself assigns a fresh disposable to;
/// - [released]: names disposed directly or referenced inside a release method;
/// - [cancelled]: names on which `.cancel()` is called.
final class _OwnershipScan extends RecursiveAstVisitor<void> {
  final owned = <String, _Created>{};
  final released = <String>{};
  final cancelled = <String>{};

  /// Instance field names declared in the scanned scope.
  final fields = <String>{};
  final _pendingAssignments = <String, _Created>{};

  void run(AstNode node) {
    node.accept(this);
    for (final entry in _pendingAssignments.entries) {
      if (fields.contains(entry.key)) {
        owned.putIfAbsent(entry.key, () => entry.value);
      }
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) {
      for (final v in node.fields.variables) {
        final name = v.name.lexeme;
        fields.add(name);
        final init = v.initializer;
        final type = init == null ? null : createdType(init);
        if (type != null && disposableTypes.contains(type)) {
          owned[name] = _Created(type, v);
        }
      }
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final name = refName(node.leftHandSide);
    final type = createdType(node.rightHandSide);
    if (name != null && type != null && disposableTypes.contains(type)) {
      _pendingAssignments.putIfAbsent(name, () => _Created(type, node));
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = refName(node.realTarget);
    if (name != null) {
      if (node.methodName.name == 'dispose') released.add(name);
      if (node.methodName.name == 'cancel') cancelled.add(name);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_releaseMethods.contains(node.name.lexeme)) {
      node.body.accept(_NameCollector(released));
    }
    super.visitMethodDeclaration(node);
  }
}

final class _NameCollector extends RecursiveAstVisitor<void> {
  _NameCollector(this.names);
  final Set<String> names;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);
}

Expression _unwrap(Expression e) => switch (e) {
  ParenthesizedExpression(:final expression) => _unwrap(expression),
  CascadeExpression(:final target) => _unwrap(target),
  _ => e,
};

/// Name of a field/variable reference: `x`, `this.x`, `(x)`, `x!`.
String? refName(Expression? e) => switch (e) {
  SimpleIdentifier(:final name) => name,
  PropertyAccess(target: ThisExpression(), :final propertyName) =>
    propertyName.name,
  ParenthesizedExpression(:final expression) => refName(expression),
  PostfixExpression(:final operand, :final operator)
      when operator.type == TokenType.BANG =>
    refName(operand),
  _ => null,
};

/// Class name constructed by [expression], seen syntactically.
///
/// Without resolution, `Foo()` and `Foo.named()` parse as method invocations,
/// so an upper-case invocation name (or target) is treated as a constructor.
String? createdType(Expression expression) {
  final e = _unwrap(expression);
  if (e is InstanceCreationExpression) {
    return e.constructorName.type.name.lexeme;
  }
  if (e is MethodInvocation && !e.isCascaded) {
    final name = e.methodName.name;
    final target = e.target;
    if (target == null) return _isUpper(name) ? name : null;
    if (target is SimpleIdentifier) {
      if (_isUpper(name)) return name; // import prefix: `m.Foo()`
      if (_isUpper(target.name)) return target.name; // `Foo.named()`
    }
  }
  return null;
}

bool _isUpper(String s) {
  final c = s.replaceFirst(RegExp(r'^_+'), '');
  return c.isNotEmpty &&
      c[0].toUpperCase() == c[0] &&
      c[0].toLowerCase() != c[0];
}
