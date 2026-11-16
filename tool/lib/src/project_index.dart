import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'audit_file.dart';

/// Project classes that transitively extend or mix in a type of
/// [disposableTypes], found by name across all [sources] (cross-file).
///
/// Syntactic: two classes with the same name in different libraries are
/// merged, and the result is only used for lookups by name. When the audit
/// resolves types it does not need this index.
Set<String> indexDisposableSubtypes(Iterable<String> sources) {
  final parents = <String, Set<String>>{};
  for (final source in sources) {
    parseString(
      content: source,
      throwIfDiagnostics: false,
    ).unit.accept(_Hierarchy(parents));
  }
  final result = <String>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final MapEntry(key: name, value: supers) in parents.entries) {
      if (result.contains(name) || disposableTypes.contains(name)) continue;
      if (supers.any(
        (s) => disposableTypes.contains(s) || result.contains(s),
      )) {
        result.add(name);
        changed = true;
      }
    }
  }
  return result;
}

final class _Hierarchy extends RecursiveAstVisitor<void> {
  _Hierarchy(this.parents);
  final Map<String, Set<String>> parents;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final supers = parents.putIfAbsent(node.namePart.typeName.lexeme, () => {});
    final extendsClause = node.extendsClause;
    if (extendsClause != null) supers.add(extendsClause.superclass.name.lexeme);
    for (final t in node.withClause?.mixinTypes ?? const <NamedType>[]) {
      supers.add(t.name.lexeme);
    }
    super.visitClassDeclaration(node);
  }
}
