import 'dart:convert';

import 'audit_project.dart';

const caveats = [
  'Leads from the syntax tree, a cross-file class index and (when the '
      'package is resolved) analyzer types; see `resolution` and each '
      'finding basis (`basis`). No runtime analysis.',
  'Findings are not confirmed bugs. Verify with code inspection and tests.',
  'Covers only rules that analyzer lints do not; run dart/flutter analyze '
      'for the rest.',
  'No source files modified.',
];

Map<String, int> _counts(ProjectReport r) {
  final counts = <String, int>{};
  for (final f in r.findings) {
    counts[f.priority] = (counts[f.priority] ?? 0) + 1;
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

String renderJson(ProjectReport r) =>
    const JsonEncoder.withIndent('  ').convert({
      'tool': 'flutter_rails_audit',
      'root': r.root,
      'scopes': r.scopes,
      'scanned_files': r.scannedFiles,
      'scanned_lines': r.scannedLines,
      'resolution': r.resolution,
      'counts_by_priority': _counts(r),
      'findings': [for (final f in r.findings) f.toJson()],
      'parse_errors': r.parseErrors,
      if (r.slop != null) 'anti_slop': r.slop!.toJson(),
      'skipped': r.skipped,
      'caveats': caveats,
    });

String renderText(ProjectReport r) {
  final s = StringBuffer()
    ..writeln('Flutter Engineering Audit (heuristic leads)')
    ..writeln('Root: ${r.root} | scope: ${r.scopes.join(', ')}')
    ..writeln(
      'Files: ${r.scannedFiles} | lines: ${r.scannedLines} | '
      'signals: ${r.findings.length}',
    )
    ..writeln('Types: ${r.resolution}');
  for (final f in r.findings) {
    s
      ..writeln()
      ..writeln('[${f.priority}] ${f.rule} | ${f.path}:${f.line}')
      ..writeln('  ${f.title}')
      ..writeln('  evidence: ${f.evidence}')
      ..writeln('  verify: ${f.check}')
      ..writeln('  basis: ${f.basis}');
  }
  if (r.parseErrors.isNotEmpty) {
    s
      ..writeln()
      ..writeln(
        'Files with syntax errors (audited anyway; results may be '
        'incomplete): ${r.parseErrors.keys.join(', ')}',
      );
  }
  if (r.skipped.isNotEmpty) {
    s
      ..writeln()
      ..writeln('Skipped: ${r.skipped.join('; ')}');
  }
  final slop = r.slop;
  if (slop != null) {
    s
      ..writeln()
      ..writeln('Anti-Slop Score (3 = no evidence ... 0 = 10+; N/E = not evaluated; not summed)');
    for (final d in slop.dimensions) {
      s.writeln('  ${d.name}: ${d.grade ?? 'N/E'}${d.note == null ? '' : ' - ${d.note}'}');
      for (final i in (d.items ?? const []).take(5)) {
        s.writeln('    ${i.path}:${i.line} ${i.title}');
      }
    }
  }
  s
    ..writeln()
    ..writeln(
      'CAVEAT: leads for inspection, NOT confirmed bugs. Run '
      'dart/flutter analyze for lint-covered rules. No source files '
      'modified.',
    );
  return s.toString();
}
