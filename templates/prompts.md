# Ready-to-use prompts for Claude Code, Codex or Hermes Agent

## 1 — Audit of a legacy Flutter project

Use the `flutter-engineering-guardrails` skill in `audit` mode. Inspect the real repository and detect its architecture, Flutter/Dart version, state management, router, tests and conventions. Do NOT modify files or apply auto-fixes. Audit lifecycle/async, controller ownership, business logic inside the UI, routes, untyped JSON, silent errors, duplication and performance at critical points. Separate **confirmed/probable/heuristic** findings, always with file:line, failure case, minimal fix and test. Prioritize P0–P3. Deliver three incremental slices of maximum value and what NOT to touch yet. Avoid proposing a new framework without evidence.

## 2 — Implement a Flutter feature with quality

Use `flutter-engineering-guardrails` in `implement` mode. First identify the existing structure and patterns, including `.flutter-rails.yaml` if present. Define the contract and UI states, the data owner, error/loading/empty paths, navigation, platforms and responsive behavior. Implement the smallest well-structured change. Respect Provider/ViewModel (or the actual framework), do not add generic layers without need, guard `await` and dispose, and create appropriate unit/widget tests. Run the available formatter, analyzer and tests, reporting actual results and limits.

## 3 — Refactor of a screen that works but is hard to maintain

Use `flutter-engineering-guardrails` in `refactor` mode. Do not change behavior, contracts or the visual design. Locate mixed responsibilities, dependencies and ownership. Write a characterization test before editing, unless a sufficient test already exists. Compare doing nothing, a small extraction and a new layer; choose the minimal effective change. Move logic out of `build()` when it adds value, fix async/lifecycle and inconsistent states, but avoid rewriting routing/state across the whole project. One structural goal per slice, with tests afterwards, a before/after comparison and rollback.

## 4 — Justified deep-refactor, without automatic rewrite

Use `flutter-engineering-guardrails` in `deep-refactor` mode and **only plan for now**. Audit the feature or app to identify verifiable causes of technical debt. Compare hotfix, incremental refactor, feature/package, and partial/full rewrite. Assess qualitative risks, contracts that must be preserved, equivalence tests, and a slice-by-slice migration plan with temporary adapters and rollback. Do not impose Riverpod/BLoC/Clean Architecture, do not move everything into packages, and do not promise CPU/RAM improvements without measurements.

## 5 — Adversarial review of AI-generated code

Use `flutter-engineering-guardrails` as a reviewer that does NOT change code. Look for behavioral problems even if `flutter analyze` passes: unusual inputs, invalid JSON, failed connection, A→B races, double tap, context after await, controllers/subscriptions without cleanup, callbacks that hide errors, coupled UI, overengineering and tests that only validate the happy path. Report only relevant findings with path:line and a proposed test; state which aspects are well founded. Avoid cosmetic feedback and invented numbers.
