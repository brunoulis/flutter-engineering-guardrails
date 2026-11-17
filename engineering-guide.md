# Dart and Flutter Engineering Guardrails

**Mission:** Produce correct, readable, testable and maintainable Flutter/Dart code with evidence-based architecture and reversible refactors. A passing analyzer is the floor, not proof of quality. Prefer fewer concepts, clear ownership and measurable improvements. **Do not introduce architecture solely for aesthetic reasons.**

## Select the package context first

Dart is a first-class scope: libraries, command-line tools, services and shared packages do not require Flutter. Inspect the affected `pubspec.yaml`, imports, entry points and workspace membership; do not infer a Flutter application from a `.dart` extension. Use the language/core references for all Dart code, then load Flutter UI/state/lifecycle references only when applicable. A mixed workspace can require both sets of checks in different packages.

For pure Dart, start with [language and API contracts](references/dart-quality-and-types.md) and [async, resources and I/O](references/dart-async-and-io.md). Use `dart analyze` and `dart test`; do not introduce Flutter, widgets, state libraries or `flutter_lints`. The historical skill ID/folder and CLI name remain `flutter-engineering-guardrails` / `flutter_rails_audit` for compatibility. UI-only report fields are N/A for Dart-only work.

## Non-negotiable rails

1. **R0 — Grounding.** Inspect actual repository and SDK/dependency versions before proposing unfamiliar APIs. Use code search, `pubspec.yaml`, analyzer, Dart/Flutter MCP and official documentation when available. Never invent methods, package versions, test outcomes or benchmark numbers.
2. **R1 — Preserve contracts.** Identify public types/exports, subclassing rights, errors, collection ownership, I/O and supported runtimes; include navigation, state and UX for Flutter. No silent public API or UX changes in a refactor.
3. **R2 — Project-first architecture.** Follow the existing working conventions. Treat Provider, ViewModel, Riverpod, BLoC, `setState`, repositories and feature folders as choices, not mandates. Never migrate libraries without a concrete benefit and migration plan.
4. **R3 — One source of truth.** Define which object owns each state, controller, stream, timer, future, cache and navigation decision. Avoid duplicate mutable state and UI/business logic drift.
5. **R4 — Async correctness.** Distinguish completion, timeout and cancellation; define stream ordering, error handling and awaited resource shutdown. For Flutter, also guard stale results and widget disposal, handle UI states and avoid side effects inside `build()`.
6. **R5 — Right-sized abstractions.** Extract code when there is a testability, readability, reuse, ownership or change-frequency benefit. No automatic repository/use-case/service for every function, widget wrapper for every expression or package for every feature.
7. **R6 — Safe UI.** Respect constraints, accessibility, text scaling, keyboard/focus, responsive targets and the project's design tokens. Do not use `kIsWeb` as a screen-width breakpoint.
8. **R7 — Performance is evidence-based.** Avoid obvious hot-path work, repeated I/O in builds and eager giant lists. Measure before claiming improvements or adding caches/isolates/rebuild optimization.
9. **R8 — Security and privacy.** Do not hardcode secrets, expose tokens in logs or blindly trust remote JSON. Preserve authorization boundaries and minimize user-data logging.
10. **R9 — Incremental diffs.** Change only what is needed; justify every file and every existing behavior the diff alters ([scope budget](references/refactor-execution.md)). Separate mechanical formatting, bug fixes, behavioral changes and architectural work. Avoid unrelated rewrites or repo-wide auto-fixes by default.
11. **R10 — Verification.** Use the smallest sufficient set of formatter, analyzer, unit/widget/integration/regression tests; extend for risky changes. Report commands **actually run** and failures honestly.
12. **R11 — Explain decisions.** Record *why* a boundary, provider or refactor is needed, alternatives rejected, compatibility/rollback risks and remaining uncertainty without excessive prose.

### R0a — Version-aware package, plugin and SDK work

Before using a package API, cleaning/refactoring its callers, or updating a dependency, verify the exact resolved version/source in the affected app or workspace package. Compare `pubspec.lock` with `.dart_tool/package_config.json` and the resolved package's metadata/source; inspect dependency overrides and git/path dependencies. For pub workspaces, locate the shared resolution at the workspace root. Constraints in `pubspec.yaml` alone do not establish the installed version, and stale generated metadata is not proof of current resolution. Identify the actual Dart SDK, package language version and any per-library language override; inspect the Flutter SDK only where relevant. Mark missing/conflicting evidence **UNVERIFIED** rather than silently resolving dependencies or upgrading the SDK.

Consult official documentation for that package version **before changing library-dependent code**: versioned pub.dev API docs or maintainer documentation, relevant defaults, deprecations and platform behavior. For Flutter/Dart framework APIs, match the actual SDK release. If versioned docs are unavailable, use matching release/tag docs, changelogs, source and tests and state unresolved behavior. Latest examples and this skill's pinned examples do not prove compatibility with the project's SDK/packages.

For an update, establish **current and intended target versions**, consult both sets of documentation and intervening migration/release notes, and assess Flutter/Dart SDK constraints, transitive packages, code generators and affected platform implementations. For native plugins, check applicable native dependency locks, build-tool requirements and minimum OS versions. Update only when requested or justified within the authorized task. Cleanup does not authorize `pub upgrade`, an SDK upgrade or a state/routing-library replacement; a newer release alone is not a reason to update.

Inspect manifest/lockfile and generated/native configuration changes; keep unrelated dependencies unchanged. Run affected analysis, unit/widget/integration checks and target-platform builds or smoke tests where needed. Preserve UI, lifecycle, navigation and persistence contracts or identify intentional migration changes and rollback. Report versions/revisions, documentation URLs or local paths, rationale and actual checks. Reuse verified evidence while resolution, SDK, platform and task assumptions remain unchanged.

## Workflow: choose one mode

| Mode | Primary outcome | May edit code? | Entry conditions |
|---|---|---|---|
| `audit` | Evidence-backed findings and ranked backlog | **No** | User asks to review, diagnose or improve quality. |
| `implement` | Minimal feature/bug fix plus tests | Yes | User asks to create/change functionality. |
| `refactor` | Behavior-preserving change to a bounded area | Yes | User asks to refactor or fix diagnosed debt. |
| `deep-refactor` | Architecture assessment + migration slices | Only when explicitly tasked with implementation; otherwise plan only | Cross-cutting redesign has evidence of value. |

When ambiguous, use `audit` for diagnosis, `implement` for requested features, and `refactor` for explicit cleanup. **Never escalate to `deep-refactor` because a file is long or code is stylistically unpleasant alone.**

### Execution loop

1. **Inventory:** classify each affected package as Dart library/CLI/service or Flutter, inspect `git status`, `pubspec.yaml`, SDK/language constraints, `analysis_options.yaml`, source/tests and existing conventions. Inspect routing/state only for relevant Flutter code. Apply R0a before library-dependent work. Read `.flutter-rails.yaml` if present; its historical name does not require Flutter. See [discovery](references/discovery-and-context.md).
2. **Characterize:** define behavior and invariants (including errors, loading, nulls, navigation, platform and existing breakpoints). For refactors, create a regression test or record a manual characterization scenario before risky edits.
3. **Choose design:** compare minimal in-place change vs local extraction vs new boundary. Use [architecture decision matrix](references/architecture-and-modularity.md), [UI and state](references/ui-state-and-layout.md) and [Dart quality](references/dart-quality-and-types.md).
4. **Implement in slices:** small diffs with clear ownership and no unrelated migrations. For refactors follow [refactor execution](references/refactor-execution.md); for broader work [deep refactor](references/deep-refactor-and-migration.md).
5. **Challenge:** explicitly look for missing edge cases, concurrency races, disposed controllers, swallowed errors, API mismatches, unbounded rebuilds, accessibility and overengineering. See [async/lifecycle](references/async-lifecycle-and-errors.md), [performance](references/performance-and-web.md) and [security/a11y](references/security-and-accessibility.md).
6. **Verify & report:** run or request target-specific verification (do not falsely mark passed). Use [testing matrix](references/testing-and-verification.md) and [review rubric](references/code-review-and-quality-score.md). Summarize behavior preserved, tests run, risks, and follow-ups.

### Reference routing (load only relevant files)

| Trigger | Read |
|---|---|
| Dart package, CLI/service, public API, null safety or collection ownership | `dart-quality-and-types.md`, `discovery-and-context.md` |
| Futures, Streams, cancellation, resource shutdown, isolates or process/file I/O | `dart-async-and-io.md`, `testing-and-verification.md` |
| Dart language/API evidence, community claims or executable counterexamples | [Dart evidence](references/dart-evidence.md) |
| New feature or architectural decision | `discovery-and-context.md`, `architecture-and-modularity.md`, `dart-quality-and-types.md` |
| Widgets, Provider/ViewModel, forms, navigation or responsive layout | `ui-state-and-layout.md`, `async-lifecycle-and-errors.md` |
| Migrating `StatefulWidget` to `StatelessWidget` + viewmodel (tabs, dialogs, forms) | [stateless-migration-and-ui-consistency](references/stateless-migration-and-ui-consistency.md) |
| Adding or changing UI: match the app's existing design, keep animations/gestures | [ui-consistency](references/ui-consistency.md) |
| Code review or technical debt report | `refactor-audit.md`, `anti-patterns-and-refactor-catalog.md`, `code-review-and-quality-score.md` |
| Explicit limited refactor or bug fix (scope budget, fail-before/pass-after test) | `refactor-execution.md`, `testing-and-verification.md` |
| Triaging findings from another agent/reviewer | `code-review-and-quality-score.md` |
| Flutter app calls Rust/C/C++ or platform channels (FFI, flutter_rust_bridge, MethodChannel) | [native-bridge-contracts](references/native-bridge-contracts.md) |
| Is CI really running the tests, pinned versions, release integrity | `quality-gates-and-ci.md` |
| Migration / cross-project rewrite | `deep-refactor-and-migration.md`, `architecture-and-modularity.md` |
| Jank, memory or Flutter web/desktop | `performance-and-web.md`, `async-lifecycle-and-errors.md` |
| Auth, data handling, accessibility | `security-and-accessibility.md` |
| Tooling setup, CI gates, or claims about sources | `quality-gates-and-ci.md`, `sources-and-rationale.md` |
| Comparing async safeguards with upstream code/tests | [Code evidence and counterexamples](references/code-evidence.md) |

## Audit and tool usage

Use the Dart/Flutter SDK tools directly, plus the skill's read-only Dart audit tool for the rules no lint covers. Prefer the repo's own scripts/CI commands when they exist. Never run commands if the user forbids command execution.

- **Verification (no source edits):** run from the package root, only on directories that exist. Dependency resolution and build caches can write artifacts; inspect prepared dependency state before a strict read-only audit.
  - Format: `dart format --output=none --set-exit-if-changed lib test` (exit 1 = files would change; nothing is written).
  - Analyze: `dart analyze`, or `flutter analyze --no-pub` in Flutter apps. `flutter analyze` exits non-zero even for *info*-level diagnostics unless `--no-fatal-infos` is passed; read the output before reporting "errors".
  - Tests: `flutter test --no-pub <target>` in quick checks; the whole suite only when the change justifies it. `dart test` for pure Dart packages.
  - Fixes: `dart fix --dry-run` only; a scoped `--apply` needs explicit scope (R9).
- **Static audit:** the analyzer parses and resolves Dart and is the primary source of signals; use the custom auditor only for relevant additional leads. Preserve the project's `analysis_options.yaml`. If extra lints are requested, select the [Dart template](templates/analysis_options_dart.yaml) for pure Dart or the [Flutter template](templates/analysis_options.yaml) for Flutter. Check installed lint/SDK compatibility first; do not add either unasked.
- **Audit tool (read-only):** `dart run <skill-dir>/tool/bin/flutter_rails_audit.dart --root <flutter-project> [--path lib] [--format text|json|sarif] [--output FILE] [--no-resolve] [--score] [--baseline FILE] [--write-baseline FILE] [--fail-on P0|P1|P2|P3] [--strict]`. It parses each file with `package:analyzer` and reports the rules no lint covers: `undisposed-controller`, `controller-created-in-build`, `future-created-in-build`, `setstate-async-callback`, `uncancelled-periodic-timer`, `mixed-navigation-styles`, `filewide-lint-suppression`, `large-dart-file`, `import-cycle` (file-level import graph: P2 across directories, P3 among siblings; verify whether intentional) and `high-fan-out` (>20 project imports, barrels excluded), plus `project-*` rules when `.flutter-rails.yaml` has a `rules:` section (see the [template](templates/project-profile.yaml)). The first `dart run` resolves the tool's dependencies by itself (writes `<skill-dir>/tool/.dart_tool/`; needs network unless the packages are already in the pub cache). If that fails, run `dart pub get --directory <skill-dir>/tool` or ask the user to. Exit 0 = report produced; 1 = `--fail-on` threshold met (only by new findings when `--baseline` is given); 2 = `--strict` and some files had syntax errors (incomplete audit); 64 = usage error; 74 = I/O error. It never modifies the audited project.
- **Type facts (hybrid):** when the audited package has prepared dependencies (`.dart_tool/package_config.json`) the tool resolves types with the analyzer; otherwise (or with `--no-resolve`) it falls back to syntax. In both modes a cross-file class index finds project subclasses/mixins of disposable types (e.g. `class AppScroll extends ScrollController` in another file). The report states `resolution`, and each finding carries `basis`: `resolved-types`, `project-index` or `syntax-tree`. Ownership *handed over* between files (a parent disposing a child's field) is still not tracked.
- **Anti-Slop Score (`--score`, opt-in):** evidence per dimension, never one summed number: duplication (equal normalized bodies of >= 60 tokens), complexity (cyclomatic > 15), mixed responsibilities (widget doing I/O, view model using `BuildContext`), useless layers (pure 1:1 forwarding classes with no contract), unused `pubspec` dependencies and logic files no test imports. It never scores file length, widget count or layer count alone. Grades are 3 (no evidence) to 0 (10+ items), `N/E` when nothing is measurable. See [score rubric](references/code-review-and-quality-score.md).
- **Size-normalized and regression modes:** reports include `rates` (signals per 1000 lines, so a 200k-line and a 2k-line project compare). `--write-baseline` stores stable fingerprints (rule + path + evidence, not line numbers); `--baseline` then marks what is new/known/fixed, and `--fail-on` blocks only new findings. `--format sarif` emits SARIF 2.1.0 for PR annotations.
- Its findings are **heuristic leads, not proven bugs** (`basis` says how much type information backed each). Inspect each before reporting it as probable/confirmed. If the tool cannot run, fall back to the `rg`/`git grep` patterns in [refactor-audit](references/refactor-audit.md) (check `rg --version`; suggest installing ripgrep per the README if missing). Do not change files in `audit` mode.
- The tool accepts Dart source, but most custom rules target Flutter patterns. It does not verify general Dart API compatibility, deep immutability, timeout cancellation, stream backpressure or CLI contracts. Prefer the analyzer and behavioral tests for those questions; a clean tool report is not Dart coverage.
- **MCP:** Use the Dart/Flutter MCP server when installed (analyzer diagnostics, symbol resolution/LSP, pub, runtime errors of a running app) and official Flutter skills for narrow tasks. Use the tool names the server actually exposes; do not invent them or assume availability. The skill is usable without MCP.

## Refactor guardrails (mandatory when modifying old code)

- First classify the request as **bug fix**, **behavior-preserving cleanup**, **API change** or **migration**. Never present the latter two as harmless cleanup.
- Build a *before* baseline for touched behavior; confirm whether failing tests already existed. No global `dart fix --apply`, blanket lint suppression, dependency swap, routing rewrite or regenerated files without explicit scope.
- Rank by **risk × impact × evidence**, not by line count alone. Address P0 data loss/crash/security and P1 lifecycle/races before P2 testability and P3 style.
- One structural theme per slice, minimal crossing of component boundaries, test after every slice, maintain an easy rollback. `git bisect`/small commits are useful if the user controls commits; **never commit without authorization**.
- Rewrites must win a written comparison: incremental effort, regression surface, testability, integration complexity, deadline and rollback. Prefer feature-by-feature migration in running app over speculative full rewrite.
- In review output, distinguish **confirmed** (repro/test/tool evidence), **probable** (specific code reasoning) and **heuristic** (audit-tool lead, search hit or lint pattern not yet inspected in context).

## Output contracts

- `audit`: inventory, confirmed/probable/heuristic findings with `file:line`, severity, trigger/consequence, attribution (introduced/pre-existing/unknown), disposition, minimal correction, risk and validation plan; 0–3 initial actions justified by findings. Remain read-only in the audited project; a clean audit may recommend no changes. Use [audit template](templates/audit-report.md).
- `implement`: what changed, why design fits project, behavior/edge cases, tests actually run, risks. Include the Regression Surface Report ([refactor-execution](references/refactor-execution.md)). Use compact write-up for trivial tasks.
- `refactor`: characterization before/after, preserved contracts, exact slice, test evidence, rollback and what was intentionally **not** refactored. Use [refactor template](templates/refactor-plan.md).
- `deep-refactor`: problem evidence, 2+ viable options including **do nothing/incremental**, migration milestones, compatibility gates, cost/risk, fallback; implement only requested slices.

Identify base/candidate and dirty diff; distinguish observed change surface, inferred paths and exercised behavior. Reuse the existing [Regression Surface Report and churn control](references/refactor-execution.md#regression-surface-report-required-output-for-implement-and-refactor), [review dispositions](references/code-review-and-quality-score.md#triage-of-findings-from-another-agent-or-reviewer) and [verification matrix](references/testing-and-verification.md#verification-matrix). Use PASS/FAIL/UNVERIFIED/N/A with reasons, actual test counts and fresh evidence tied to candidate/configuration/artifact. Host OS, VM/widget/browser/device integration and release are separate claims. Keep local low-risk deliveries compact with justified N/A; no infrastructure or JSON/SARIF migration is required for these documentary fields.

When assigning a score, **never invent metrics**. Mark dimensions `not measured` or `needs verification` where evidence is absent. For major changes, explicitly ask whether the work will make the repository easier for the *next* maintainer.
