---
name: flutter-engineering-guardrails
description: >-
  Engineering rails for creating, reviewing, auditing and refactoring Flutter/Dart code.
  Activate for Flutter features, widgets, Provider/ViewModel/BLoC/Riverpod state, Dart
  async/lifecycle bugs, architecture decisions, Flutter web/desktop performance,
  code quality reviews, technical debt, incremental refactors and deep migrations.
  Use modes audit, implement, refactor or deep-refactor. Prioritizes verified behavior,
  minimum useful complexity and project conventions over generic boilerplate.
license: MIT
compatibility: Flutter/Dart SDK (Dart 3.13+) for project checks and the bundled Dart audit tool (tool/, one-time dart pub get); ripgrep (rg) recommended for ad-hoc search, git grep as fallback. No other runtime or build step.
metadata:
  version: "1.0.0"
  family: "engineering-guardrails"
---

# Flutter Engineering Guardrails

**Mission:** Produce correct, readable, testable and maintainable Flutter/Dart code with evidence-based architecture and reversible refactors. A passing analyzer is the floor, not proof of quality. Prefer fewer concepts, clear ownership and measurable improvements. **Do not introduce architecture solely for aesthetic reasons.**

## Non-negotiable rails

1. **R0 — Grounding.** Inspect actual repository and SDK/dependency versions before proposing unfamiliar APIs. Use code search, `pubspec.yaml`, analyzer, Dart/Flutter MCP and official documentation when available. Never invent methods, package versions, test outcomes or benchmark numbers.
2. **R1 — Preserve contracts.** For existing code, identify observable behavior, navigation, state, API shapes, persistence, responsive behavior and supported platforms. No silent public API or UX changes in a refactor.
3. **R2 — Project-first architecture.** Follow the existing working conventions. Treat Provider, ViewModel, Riverpod, BLoC, `setState`, repositories and feature folders as choices, not mandates. Never migrate libraries without a concrete benefit and migration plan.
4. **R3 — One source of truth.** Define which object owns each state, controller, stream, timer, future, cache and navigation decision. Avoid duplicate mutable state and UI/business logic drift.
5. **R4 — Async correctness.** Handle loading, empty, success and error paths as applicable; guard stale results and widget disposal; dispose resources owned by the component; avoid swallowing exceptions and side effects inside `build()`.
6. **R5 — Right-sized abstractions.** Extract code when there is a testability, readability, reuse, ownership or change-frequency benefit. No automatic repository/use-case/service for every function, widget wrapper for every expression or package for every feature.
7. **R6 — Safe UI.** Respect constraints, accessibility, text scaling, keyboard/focus, responsive targets and the project's design tokens. Do not use `kIsWeb` as a screen-width breakpoint.
8. **R7 — Performance is evidence-based.** Avoid obvious hot-path work, repeated I/O in builds and eager giant lists. Measure before claiming improvements or adding caches/isolates/rebuild optimization.
9. **R8 — Security and privacy.** Do not hardcode secrets, expose tokens in logs or blindly trust remote JSON. Preserve authorization boundaries and minimize user-data logging.
10. **R9 — Incremental diffs.** Change only what is needed. Separate mechanical formatting, bug fixes, behavioral changes and architectural work. Avoid unrelated rewrites or repo-wide auto-fixes by default.
11. **R10 — Verification.** Use the smallest sufficient set of formatter, analyzer, unit/widget/integration/regression tests; extend for risky changes. Report commands **actually run** and failures honestly.
12. **R11 — Explain decisions.** Record *why* a boundary, provider or refactor is needed, alternatives rejected, compatibility/rollback risks and remaining uncertainty without excessive prose.

## Workflow: choose one mode

| Mode | Primary outcome | May edit code? | Entry conditions |
|---|---|---|---|
| `audit` | Evidence-backed findings and ranked backlog | **No** | User asks to review, diagnose or improve quality. |
| `implement` | Minimal feature/bug fix plus tests | Yes | User asks to create/change functionality. |
| `refactor` | Behavior-preserving change to a bounded area | Yes | User asks to refactor or fix diagnosed debt. |
| `deep-refactor` | Architecture assessment + migration slices | Only when explicitly tasked with implementation; otherwise plan only | Cross-cutting redesign has evidence of value. |

When ambiguous, use `audit` for diagnosis, `implement` for requested features, and `refactor` for explicit cleanup. **Never escalate to `deep-refactor` because a file is long or code is stylistically unpleasant alone.**

### Execution loop

1. **Inventory:** inspect `git status`, `pubspec.yaml` and SDK constraints, `analysis_options.yaml`, relevant source/tests, routing, state package and existing conventions. Check whether a `.flutter-rails.yaml` profile exists; if absent infer without inventing. See [discovery](references/discovery-and-context.md).
2. **Characterize:** define behavior and invariants (including errors, loading, nulls, navigation, platform and existing breakpoints). For refactors, create a regression test or record a manual characterization scenario before risky edits.
3. **Choose design:** compare minimal in-place change vs local extraction vs new boundary. Use [architecture decision matrix](references/architecture-and-modularity.md), [UI and state](references/ui-state-and-layout.md) and [Dart quality](references/dart-quality-and-types.md).
4. **Implement in slices:** small diffs with clear ownership and no unrelated migrations. For refactors follow [refactor execution](references/refactor-execution.md); for broader work [deep refactor](references/deep-refactor-and-migration.md).
5. **Challenge:** explicitly look for missing edge cases, concurrency races, disposed controllers, swallowed errors, API mismatches, unbounded rebuilds, accessibility and overengineering. See [async/lifecycle](references/async-lifecycle-and-errors.md), [performance](references/performance-and-web.md) and [security/a11y](references/security-and-accessibility.md).
6. **Verify & report:** run or request target-specific verification (do not falsely mark passed). Use [testing matrix](references/testing-and-verification.md) and [review rubric](references/code-review-and-quality-score.md). Summarize behavior preserved, tests run, risks, and follow-ups.

### Reference routing (load only relevant files)

| Trigger | Read |
|---|---|
| New feature or architectural decision | `discovery-and-context.md`, `architecture-and-modularity.md`, `dart-quality-and-types.md` |
| Widgets, Provider/ViewModel, forms, navigation or responsive layout | `ui-state-and-layout.md`, `async-lifecycle-and-errors.md` |
| Code review or technical debt report | `refactor-audit.md`, `anti-patterns-and-refactor-catalog.md`, `code-review-and-quality-score.md` |
| Explicit limited refactor | `refactor-execution.md`, `testing-and-verification.md` |
| Migration / cross-project rewrite | `deep-refactor-and-migration.md`, `architecture-and-modularity.md` |
| Jank, memory or Flutter web/desktop | `performance-and-web.md`, `async-lifecycle-and-errors.md` |
| Auth, data handling, accessibility | `security-and-accessibility.md` |
| Tooling setup, CI gates, or claims about sources | `quality-gates-and-ci.md`, `sources-and-rationale.md` |

## Audit and tool usage

Use the Dart/Flutter SDK tools directly, plus the skill's read-only Dart audit tool for the rules no lint covers. Prefer the repo's own scripts/CI commands when they exist. Never run commands if the user forbids command execution.

- **Verification (read-only):** run from the package root, only on directories that exist.
  - Format: `dart format --output=none --set-exit-if-changed lib test` (exit 1 = files would change; nothing is written).
  - Analyze: `dart analyze`, or `flutter analyze --no-pub` in Flutter apps. `flutter analyze` exits non-zero even for *info*-level diagnostics unless `--no-fatal-infos` is passed; read the output before reporting "errors".
  - Tests: `flutter test --no-pub <target>` in quick checks; the whole suite only when the change justifies it. `dart test` for pure Dart packages.
  - Fixes: `dart fix --dry-run` only; a scoped `--apply` needs explicit scope (R9).
- **Static audit = analyzer lints + the Dart audit tool.** The analyzer parses and resolves real Dart, so it is the primary source of signals. Report its diagnostics under the project's own `analysis_options.yaml`; if the user wants the guardrail lints, propose [`templates/analysis_options.yaml`](templates/analysis_options.yaml) (do not add it unasked).
- **Audit tool (read-only):** `dart run <skill-dir>/tool/bin/flutter_rails_audit.dart --root <flutter-project> [--path lib] [--format text|json] [--output FILE]`. It parses each file with `package:analyzer` and reports the rules no lint covers: `undisposed-controller`, `controller-created-in-build`, `future-created-in-build`, `setstate-async-callback`, `uncancelled-periodic-timer`, `mixed-navigation-styles`, `filewide-lint-suppression`, `large-dart-file`. The first `dart run` resolves the tool's dependencies by itself (writes `<skill-dir>/tool/.dart_tool/`; needs network unless the packages are already in the pub cache). If that fails, run `dart pub get --directory <skill-dir>/tool` or ask the user to. Exit 0 = report produced; 64 = usage error. It never modifies the audited project.
- Its findings are **heuristic leads, not proven bugs** (syntax only: no type resolution, no cross-file ownership). Inspect each before reporting it as probable/confirmed. If the tool cannot run, fall back to the `rg`/`git grep` patterns in [refactor-audit](references/refactor-audit.md) (check `rg --version`; suggest installing ripgrep per the README if missing). Do not change files in `audit` mode.
- **MCP:** Use the Dart/Flutter MCP server when installed (analyzer diagnostics, symbol resolution/LSP, pub, runtime errors of a running app) and official Flutter skills for narrow tasks. Use the tool names the server actually exposes; do not invent them or assume availability. The skill is usable without MCP.

## Refactor guardrails (mandatory when modifying old code)

- First classify the request as **bug fix**, **behavior-preserving cleanup**, **API change** or **migration**. Never present the latter two as harmless cleanup.
- Build a *before* baseline for touched behavior; confirm whether failing tests already existed. No global `dart fix --apply`, blanket lint suppression, dependency swap, routing rewrite or regenerated files without explicit scope.
- Rank by **risk × impact × evidence**, not by line count alone. Address P0 data loss/crash/security and P1 lifecycle/races before P2 testability and P3 style.
- One structural theme per slice, minimal crossing of component boundaries, test after every slice, maintain an easy rollback. `git bisect`/small commits are useful if the user controls commits; **never commit without authorization**.
- Rewrites must win a written comparison: incremental effort, regression surface, testability, integration complexity, deadline and rollback. Prefer feature-by-feature migration in running app over speculative full rewrite.
- In review output, distinguish **confirmed** (repro/test/tool evidence), **probable** (specific code reasoning) and **heuristic** (audit-tool lead, search hit or lint pattern not yet inspected in context).

## Output contracts

- `audit`: inventory, confirmed/probable/heuristic findings with `file:line`, severity, consequences, minimal correction, risk and validation plan; a prioritized 3-slice backlog. Use [audit template](templates/audit-report.md).
- `implement`: what changed, why design fits project, behavior/edge cases, tests actually run, risks. Use compact write-up for trivial tasks.
- `refactor`: characterization before/after, preserved contracts, exact slice, test evidence, rollback and what was intentionally **not** refactored. Use [refactor template](templates/refactor-plan.md).
- `deep-refactor`: problem evidence, 2+ viable options including **do nothing/incremental**, migration milestones, compatibility gates, cost/risk, fallback; implement only requested slices.

When assigning a score, **never invent metrics**. Mark dimensions `not measured` or `needs verification` where evidence is absent. For major changes, explicitly ask whether the work will make the repository easier for the *next* maintainer.
