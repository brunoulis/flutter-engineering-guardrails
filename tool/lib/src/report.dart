import 'dart:convert';

import 'audit_project.dart';
import 'baseline.dart';
import 'finding.dart';

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

/// Findings per 1000 scanned lines, so projects of different size compare.
double perKloc(num count, ProjectReport r) => r.scannedLines == 0
    ? 0
    : double.parse((count * 1000 / r.scannedLines).toStringAsFixed(2));

Map<String, Object?> _rates(ProjectReport r) => {
  'findings_per_kloc': perKloc(r.findings.length, r),
  'by_priority_per_kloc': {
    for (final e in _counts(r).entries) e.key: perKloc(e.value, r),
  },
  if (r.slop != null)
    'anti_slop_items_per_kloc': {
      for (final d in r.slop!.dimensions)
        if (d.items != null) d.name: perKloc(d.items!.length, r),
    },
};

Map<String, Object> _baseline(BaselineDiff d) => {
  'new': d.added.length,
  'known': d.known.length,
  'fixed': d.fixed,
  'new_findings': [for (final f in d.added) f.toJson()],
};

String renderJson(ProjectReport r, {BaselineDiff? diff}) =>
    const JsonEncoder.withIndent('  ').convert({
      'tool': 'flutter_rails_audit',
      'root': r.root,
      'scopes': r.scopes,
      'scanned_files': r.scannedFiles,
      'scanned_lines': r.scannedLines,
      'resolution': r.resolution,
      'counts_by_priority': _counts(r),
      'rates': _rates(r),
      if (diff != null) 'baseline': _baseline(diff),
      'findings': [for (final f in r.findings) f.toJson()],
      'parse_errors': r.parseErrors,
      if (r.slop != null) 'anti_slop': r.slop!.toJson(),
      'skipped': r.skipped,
      'caveats': caveats,
    });

String renderText(ProjectReport r, {BaselineDiff? diff}) {
  final s = StringBuffer()
    ..writeln('Flutter Engineering Audit (heuristic leads)')
    ..writeln('Root: ${r.root} | scope: ${r.scopes.join(', ')}')
    ..writeln(
      'Files: ${r.scannedFiles} | lines: ${r.scannedLines} | '
      'signals: ${r.findings.length}',
    )
    ..writeln('Types: ${r.resolution}')
    ..writeln('Rate: ${perKloc(r.findings.length, r)} signals per 1000 lines');
  if (diff != null) {
    s.writeln(
      'Baseline: ${diff.added.length} new, ${diff.known.length} known, '
      '${diff.fixed} fixed',
    );
  }
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
      ..writeln(
        'Anti-Slop Score (3 = no evidence ... 0 = 10+; N/E = not evaluated; not summed)',
      );
    for (final d in slop.dimensions) {
      s.writeln(
        '  ${d.name}: ${d.grade ?? 'N/E'}${d.note == null ? '' : ' - ${d.note}'}',
      );
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

const _sarifLevel = {'P0': 'error', 'P1': 'error', 'P2': 'warning'};

/// SARIF 2.1.0, one result per finding. With [diff], `baselineState` is
/// `new` or `unchanged`.
String renderSarif(ProjectReport r, {BaselineDiff? diff}) {
  final prints = fingerprints(r.findings);
  final added = diff == null
      ? null
      : (Set<Finding>.identity()..addAll(diff.added));
  final rules = {for (final f in r.findings) f.rule};
  return const JsonEncoder.withIndent('  ').convert({
    r'$schema': 'https://json.schemastore.org/sarif-2.1.0.json',
    'version': '2.1.0',
    'runs': [
      {
        'tool': {
          'driver': {
            'name': 'flutter_rails_audit',
            'rules': [
              for (final id in rules.toList()..sort()) {'id': id},
            ],
          },
        },
        'results': [
          for (var i = 0; i < r.findings.length; i++)
            {
              'ruleId': r.findings[i].rule,
              'level': _sarifLevel[r.findings[i].priority] ?? 'note',
              'message': {
                'text':
                    '${r.findings[i].title} (heuristic lead; '
                    'verify: ${r.findings[i].check})',
              },
              'locations': [
                {
                  'physicalLocation': {
                    'artifactLocation': {'uri': r.findings[i].path},
                    'region': {'startLine': r.findings[i].line},
                  },
                },
              ],
              'partialFingerprints': {'railsFingerprint/v1': prints[i]},
              if (added != null)
                'baselineState': added.contains(r.findings[i])
                    ? 'new'
                    : 'unchanged',
            },
        ],
      },
    ],
  });
}
