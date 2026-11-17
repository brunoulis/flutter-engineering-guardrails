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

Identify the affected package from its pubspec and callers. Use its resolved SDK and APIs, existing architecture, and public behavior. For pure Dart, keep the change independent of Flutter.

For a local implementation, trace the affected state or value from input to output. Identify who owns each changed resource and what happens on error, cancellation or disposal. Check asynchronous behavior at the point a result is consumed. Exercise the changed contract and a relevant failure path with the package's analyzer and tests.

When state changes can invoke listeners or caller-supplied work, trace what happens if the callback calls back into the controller before the original operation returns. Exercise immediate success, a synchronous throw, and delayed completion wherever these can change the outcome. Keep repeated legal retries from growing the call stack. In widget or unit tests, wait for an observed lifecycle or writer event when its exact scheduling is unspecified.

Open additional guidance when the task calls for it.

- For widget, controller or subscription lifetime decisions, consult [async lifecycle and errors](references/async-lifecycle-and-errors.md).
- For a native plugin or FFI boundary, consult [native bridge contracts](references/native-bridge-contracts.md).
- For audit, refactor, migration, dependency changes, performance work or a cross-package change, use the applicable mode and references in the [engineering guide](engineering-guide.md). Audits are read-only unless the user requests edits.

Answer the question first. For an implementation, state the behavior delivered, the checks actually run and any limitation that matters to the caller. For an audit, lead with the finding and its consequence. Match the level of detail the user requested.
