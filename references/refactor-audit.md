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

### Static signals: analyzer first, then the audit tool

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

2. **Audit tool** for the rules no lint covers. It parses each file with `package:analyzer` (syntax tree, no type resolution) and never modifies the project:

   ```bash
   # optional: the first `dart run` does this by itself (needs network unless cached)
   dart pub get --directory <skill-dir>/tool

   dart run <skill-dir>/tool/bin/flutter_rails_audit.dart --root . --format text
   dart run <skill-dir>/tool/bin/flutter_rails_audit.dart --root . --path lib --path test --format json --output audit.json
   ```

   | Rule | Priority | Flags | Does not flag |
   |---|---|---|---|
   | `setstate-async-callback` | P1 | `setState(() async { ... })` | synchronous callbacks |
   | `undisposed-controller` | P2 | a field the class itself fills with a disposable (`TextEditingController`, `ScrollController`, `PageController`, `AnimationController`, `TabController`, `FocusNode`, `ValueNotifier`, …), in its declaration or by assignment, with no `.dispose()` on it and no reference to it inside `dispose()`/`close()`/`onClose()` | controllers injected through the constructor; disposal via `?.`, cascades or a list iterated in `dispose()` |
   | `controller-created-in-build` | P2 | a disposable constructed inside `build()`, e.g. `controller: TextEditingController()` or a `?? ValueNotifier(...)` fallback | `x ??= ...`; assignment to a field (the rule above checks its disposal) |
   | `future-created-in-build` | P2 | `FutureBuilder(future: load())` / `StreamBuilder(stream: watch())` inside `build()` | a stored field, `_f ??= load()`, builders outside `build()` |
   | `uncancelled-periodic-timer` | P2 | `Timer.periodic` stored in a variable/field never cancelled, or discarded without cancelling itself | `cancel()` on the holder, references in `dispose()`, `timer.cancel()` in the callback, a timer returned or passed on |
   | `mixed-navigation-styles` | P2 | more than one of `Navigator.*`, `Get.to/off/back…`, go_router (`context.go/push/pop…`, `GoRouter.of`) across the scope | a single API |
   | `filewide-lint-suppression` | P3 | `// ignore_for_file:` comments | the same text inside strings |
   | `large-dart-file` | P3 | files over `--large-file-lines` (default 700) | |

   The JSON report keeps `confidence: "heuristic"` and adds `basis: "syntax-tree"`, `parse_errors` (files with syntax errors are still audited) and `skipped`. Exit code 0 means a report was produced, whatever it contains; 64 is a usage error.

3. **Fallback: targeted search** when the audit tool cannot run (no network for the first `dart pub get`, Dart older than 3.13) or for ad-hoc follow-up questions. Use `rg` (ripgrep), run from the package root. Check `rg --version` first; if it is missing, use `git grep` and suggest installing ripgrep (see the README). The regexes below work unchanged in both. Always exclude generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.mocks.dart`); `--type dart` with `lib` (and `test` when relevant) already keeps platform folders out.

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

- Audit-tool findings are **heuristic leads**: the tool sees syntax, not types, so a subclass of a controller or ownership handed to another file is invisible to it. Search hits are weaker still: they do not parse Dart, so expect false positives (comments, strings, ownership held elsewhere) and false negatives.
- Neither lints nor searches replace instrumentation, tests or ownership inspection.
- Do not assign "quality" percentages based on the number of findings.

### Prioritization and plan

Classify each item by real impact, cost, regression risk and existing coverage. Offer **at most three initial slices**, leaving a backlog with dependencies for the rest. Do not use "rewrite everything" as an automatic diagnosis.

Use the template [`../templates/audit-report.md`](../templates/audit-report.md).
