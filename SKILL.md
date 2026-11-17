---
name: flutter-engineering-guardrails
description: >-
  Use when creating, reviewing or refactoring Dart libraries, packages, CLI tools,
  services or Flutter apps. Applies to Dart types, public APIs, Futures/Streams,
  resource ownership, isolates and dependency migrations, as well as Flutter
  widgets, state, navigation, lifecycle, layout and performance.
license: MIT
compatibility: Project-compatible Dart SDK for Dart checks; Flutter SDK only for Flutter packages. Bundled audit tool requires Dart >=3.13.0 <4.0.0 and its own dependency resolution. The tool's minimum SDK does not set the audited project's minimum. ripgrep recommended; git grep fallback.
metadata:
  version: "1.2.0"
  family: "engineering-guardrails"
---

# Dart and Flutter engineering guardrails

Work from the affected pubspec, callers and resolved SDK. Keep pure Dart independent of Flutter. Trace resource ownership through cancellation, errors and disposal. When listeners or writers can call back into a controller, publish consistent state before invoking them. Handle immediate success, synchronous throws and delayed completion; a finite chain of legal retries must finish without growing the stack.

Test the public contract across both immediate and deferred scheduling. To exercise a join, hold the first write open with a Completer and wait for the writer-start event before joining. A synchronous throw may already have finished when flush returns; a later call can legitimately be a new attempt. Await an observable event before inspecting calls.

Use the affected analyzer and tests. Read related source together; inspect summary output first and expand failing checks. For [lifecycle](references/async-lifecycle-and-errors.md) or [native bridges](references/native-bridge-contracts.md), read the relevant section. For audits, migrations, performance or wider refactors, select the matching workflow in the [engineering guide](engineering-guide.md). Audit read-only unless edits are requested. Report the result, checks and material limits.
