# AUDIT mode — diagnosis without touching the code

## Contract

**FORBIDDEN: editing, formatting or running auto-fixes.** You may read, run non-mutating analysis tools and propose a plan. Distinguish a demonstrated finding from a risk identified by inspection.

### Initial inventory

- Scope: package(s), features, tests, `analysis_options.yaml`, state/routing/serialization, known debt.
- Baseline: `git status`, `dart analyze`/`flutter analyze` if possible; existing tests; branches/flows that must not be touched.
- Environment details: actual SDK versions, platforms, relevant packages, existing CI commands.
- Imported dependencies and **generated code**; do not report generated code as a manual refactor.
- Risk signals: recurring incidents, hard-to-make changes, production errors, flaky tests, measured leaks or jank.

### Observation catalog (evidence before opinion)

| Category | Look for | Interpret carefully |
|---|---|---|
| Correctness | unhandled errors, unsafe `!`, `Map` with casts, scattered rules | Needs a contract and a concrete case |
| Async and lifecycle | `await`→context/notify, controllers without dispose, listeners/timers | Check the **real owner** and the order of events |
| State | double source of truth, massive notify, unnotified mutations | The state framework is not the problem by default |
| Routing | `GetX` mixed with `Navigator`/go_router, inconsistent history | Verify that the mix actually breaks flows |
| Separation | `build()` does I/O, scattered business logic, UI coupled to HTTP | Extract only if it improves understanding/testing |
| Data | JSON serialization in widgets, magic backend strings | Type the boundary; do not blindly type everything |
| Tests | critical logic without tests, tests coupled to internal details | Start with observable behavior |
| Performance | giant eager lists, heavy work in build, measured jank | Measure and compare before claiming a cause |
| Accessibility | icons without semantics, focus and keyboard, text scaling | Test the real interaction |
| Hygiene | `ignore_for_file`, dead code, lints/format | Low priority unless there is a functional effect |

### Severity and confidence

- **P0 / critical:** security, data loss/corruption, severe reproducible crash. Requires concrete evidence.
- **P1 / high:** probable functional error, real race, memory leak with impact, release blocker.
- **P2 / medium:** maintenance, testability, real duplication, fragility.
- **P3 / low:** cosmetic, names or micro-duplications without impact.

Evidence for each finding:

```text
ID: FL-007
Level: P1 | Confidence: probable
File: lib/features/orders/order_view_model.dart:123
Signal: a late response can overwrite a later search.
Consequence: data from another search is displayed.
Test: A→B test with controlled Futures, B completes before A.
Minimal fix: discard the stale generation inside the existing ViewModel.
Change risk: low / affects only that flow.
```

**Confidence:** `confirmed` = test, stack trace, reproduction or unambiguous diagnosis; `probable` = specific reasoning about the real flow; `heuristic` = static search or lint pattern not yet confirmed. **Never mark "confirmed leak" based on a controller's name.**

### Static signals: analyzer first, then targeted search

1. **Analyzer.** Run `dart analyze` (or `flutter analyze --no-pub`) under the project's own `analysis_options.yaml` and report the diagnostics as they are. They come from the real Dart parser and resolver. If the project lacks the lints below and the user agrees, evaluate them with [`../templates/analysis_options.yaml`](../templates/analysis_options.yaml) **without committing it** unless asked:

   | Lint | Covers |
   |---|---|
   | `use_build_context_synchronously` | `await` followed by `context`/`Navigator`/`ScaffoldMessenger` without a `mounted` guard |
   | `empty_catches` | swallowed exceptions |
   | `avoid_print` | `print()` in production code |
   | `avoid_void_async` | `void initState() async` and other fire-and-forget `async` methods |
   | `cancel_subscriptions` / `close_sinks` | `StreamSubscription` / `StreamController` fields never cancelled/closed |
   | `discarded_futures` / `unawaited_futures` | futures dropped without `await` or `unawaited` |
   | `avoid_dynamic_calls` | member access on `dynamic`, typical of raw `Map<String, dynamic>` handling |

2. **Targeted search** for patterns no lint covers, run from the package root. Use `rg` (ripgrep). Check `rg --version` first; if it is missing, use `git grep` and suggest installing ripgrep (see the README). The regexes below work unchanged in both. Always exclude generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.mocks.dart`); `--type dart` with `lib` (and `test` when relevant) already keeps platform folders out.

   ```bash
   # ripgrep (preferred)
   rg -n --type dart -g '!*.g.dart' -g '!*.freezed.dart' -g '!*.gr.dart' -g '!*.mocks.dart' 'Timer\.periodic\(' lib

   # Fallback: git grep (add --untracked to include files not yet added to git)
   git grep -nE 'Timer\.periodic\(' -- 'lib/*.dart' ':!*.g.dart' ':!*.freezed.dart' ':!*.gr.dart' ':!*.mocks.dart'
   ```

   | Signal | Pattern (ERE) | Then verify |
   |---|---|---|
   | `async` callback inside `setState` | `setState\([[:space:]]*\([[:space:]]*\)[[:space:]]*async` | Move `await` out of `setState`; check `mounted` (P1) |
   | Future created in `build` | `future:[[:space:]]*[A-Za-z0-9_.]+\(` | Is the hit inside `build()`? Is the `Future` cached in state? (P2) |
   | Possibly undisposed controller | `(TextEditingController\|ScrollController\|PageController\|AnimationController\|TabController\|FocusNode)\(` | Compare the hit files (`rg -l`) with files that never call dispose (`rg --files-without-match '\.dispose\(' --type dart lib`); files on both lists are leads. Confirm the real owner (P2) |
   | Periodic timer | `Timer\.periodic\(` | Is it stored and cancelled in `dispose`/`close`? (P2) |
   | File-wide lint suppression | `ignore_for_file:` | Is each suppression justified? Can its scope be narrowed? (P3) |
   | Mixed navigation APIs | `Get\.(to\|off\|offAll\|back)\(`, `Navigator\.(push\|pop\|of)`, `context\.(go\|push\|pop)\(` | Count files per API; confirm the coexistence is intentional and route/deep-link tests exist (P2) |
   | Large file | `rg -c '' --type dart lib` (lines per file; `git grep -c ''` as fallback) | Review cohesion; never split by size alone (P3) |

   In the table, `\|` is an escaped pipe for Markdown; write `|` in the actual regex. Run the two dispose searches as separate commands and compare their output: piping one `rg` into another is shell-dependent on Windows (backslash paths).

- Search hits are **heuristic leads**: they do not parse Dart, so expect false positives (comments, strings, ownership held elsewhere) and false negatives.
- Neither lints nor searches replace instrumentation, tests or ownership inspection.
- Do not assign "quality" percentages based on the number of findings.

### Prioritization and plan

Classify each item by real impact, cost, regression risk and existing coverage. Offer **at most three initial slices**, leaving a backlog with dependencies for the rest. Do not use "rewrite everything" as an automatic diagnosis.

Use the template [`../templates/audit-report.md`](../templates/audit-report.md).
