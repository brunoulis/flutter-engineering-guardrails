/// A lead produced by the audit. Never a confirmed bug: the audit parses
/// syntax only (no type resolution, no cross-file ownership).
final class Finding {
  const Finding({
    required this.rule,
    required this.priority,
    required this.path,
    required this.line,
    required this.title,
    required this.evidence,
    required this.check,
  });

  final String rule;

  /// `P0`..`P3`, as defined in references/refactor-audit.md.
  final String priority;

  /// Path relative to the audit root, with `/` separators.
  final String path;

  /// 1-based line.
  final int line;
  final String title;

  /// The trimmed source line (at most 140 characters).
  final String evidence;

  /// What the agent must verify before reporting it as probable/confirmed.
  final String check;

  Map<String, Object> toJson() => {
    'rule': rule,
    'priority': priority,
    'confidence': 'heuristic',
    'basis': 'syntax-tree',
    'path': path,
    'line': line,
    'title': title,
    'evidence': evidence,
    'check': check,
  };

  static int compare(Finding a, Finding b) {
    var c = a.priority.compareTo(b.priority);
    if (c != 0) return c;
    c = a.path.compareTo(b.path);
    if (c != 0) return c;
    c = a.line.compareTo(b.line);
    if (c != 0) return c;
    return a.rule.compareTo(b.rule);
  }
}
