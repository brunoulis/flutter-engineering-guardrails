import 'dart:convert';

import 'finding.dart';

/// Stable identity of each finding, independent of line numbers so unrelated
/// edits above it do not make it "new". Identical findings in one file are
/// told apart by occurrence order.
List<String> fingerprints(List<Finding> findings) {
  final seen = <String, int>{};
  return [
    for (final f in findings)
      () {
        final key = '${f.rule}|${f.path}|${f.evidence}';
        final n = seen[key] = (seen[key] ?? 0) + 1;
        return '$key|$n';
      }(),
  ];
}

String renderBaseline(List<Finding> findings) => const JsonEncoder.withIndent(
  '  ',
).convert({'version': 1, 'fingerprints': fingerprints(findings)..sort()});

/// Throws [FormatException] when [text] is not a baseline file.
Set<String> parseBaseline(String text) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const FormatException('baseline is not valid JSON');
  }
  final list = json is Map ? json['fingerprints'] : null;
  if (list is! List) {
    throw const FormatException('baseline has no "fingerprints" list');
  }
  return {for (final e in list) e.toString()};
}

/// Findings compared with a baseline.
final class BaselineDiff {
  BaselineDiff(List<Finding> findings, Set<String> baseline) {
    final prints = fingerprints(findings);
    for (var i = 0; i < findings.length; i++) {
      (baseline.contains(prints[i]) ? known : added).add(findings[i]);
    }
    fixed = baseline.difference(prints.toSet()).length;
  }

  final added = <Finding>[];
  final known = <Finding>[];

  /// Baseline entries that no longer appear.
  late final int fixed;
}
