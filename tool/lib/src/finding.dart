/// A lead produced by the audit. Never a confirmed bug; [basis] says how much
/// the audit knew about types.
final class Finding {
  const Finding({
    required this.rule,
    required this.priority,
    required this.path,
    required this.line,
    required this.title,
    required this.evidence,
    required this.check,
    this.basis = 'syntax-tree',
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

  /// How the type facts were obtained: `syntax-tree`, `project-index`
  /// (cross-file class hierarchy) or `resolved-types` (analyzer resolution).
  final String basis;

  Map<String, Object> toJson() => {
    'rule': rule,
    'priority': priority,
    'confidence': 'heuristic',
    'basis': basis,
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
