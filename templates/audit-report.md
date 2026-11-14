# Dart / Flutter Engineering Audit — [scope] / [date]

## Scope and verified facts
- Package kind (Dart library/CLI/service or Flutter), runtime targets and applicable sections; UI fields are N/A for Dart-only work:
- Package, main paths and platform(s):
- SDK/conventions, `analysis_options.yaml`, state/routing dependencies:
- Packages/plugins touched: exact resolved versions/sources, SDK/platform and evidence or discrepancies:
- Version-matched official documentation consulted (URLs or local paths), relevant API/default/deprecation facts:
- If updating: current → target, task justification, migration notes, SDK/native-platform compatibility, checks and rollback:
- Available tests and checks run (with output):
- Out of scope:

## Current state (no invented diagnoses)
- Confirmed findings:
- Probable findings:
- Heuristic signals pending inspection:

## Prioritized findings
| ID | P0–P3 | Confidence | File:line | Scenario / impact | Minimal change | Test / risk |
|---|---|---|---|---|---|---|
| FL-001 | P1 | probable | `lib/...:123` | ... | ... | ... |

## Cross-cutting risks
- Public exports/subtyping, language version, input and collection ownership contracts:
- Async ordering, timeout/cancellation, resource shutdown and CLI/service I/O:
- State and resource ownership:
- Dependencies/boundaries:
- Navigation and backend contracts:
- Web/desktop/responsive:
- Privacy, errors and accessibility:

## Initial actions: 0–3 justified by findings
List only supported work: [Finding → goal → scope → test → rollback].
If none is justified, state that no changes are recommended.

## Not for now
- [Abstractions, migrations or cosmetic fixes without enough value]

## Verification and limits
- PASS actually run:
- Not run / reasons:
- Metrics not available:
- Residual risks / product decisions:
