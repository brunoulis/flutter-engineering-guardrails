# Risk-based testing and validation strategy

For pure Dart, use the package's Dart analyzer and unit/contract tests; Flutter is not required. For Flutter, the [official guide](https://docs.flutter.dev/testing/overview) distinguishes unit, widget and integration tests. Combine checks according to cost and criticality. Never claim coverage that was not measured.

## Progressive gate

| Change | Suggested minimum check | Expand when... |
|---|---|---|
| Small text/style | `dart format`/partial analyzer + visual inspection | Responsive/a11y or fragile layout |
| Pure function | Unit tests + analyze | It has business decisions |
| Dart public API / library extraction | Consumer compile/analyze checks, exports, subtype rights and regression tests | Minimum language version or dependency range changes |
| Collections / parser | Malformed input, aliases, nested mutation and snapshot/view contracts | Equality/hash keys or external schema changes |
| Dart async / streams | Controlled ordering, errors, timeout effects, concurrent work and awaited cleanup | Buffering, cancellation or shutdown changes |
| CLI / service I/O | Input/output, stderr/exit code, resource cleanup and controlled integration | Processes, signals, sockets or OS-specific behavior changes |
| Form/ViewModel | Unit tests for state and errors + widget test for interaction | It validates, navigates, persists or uses several requests |
| Controller/stream/listener | Lifecycle test: create, use, unmount, return | There are timers, cancellations, race conditions |
| Routing/deep links | Widget/integration test for entry/back/params | Web/history/auth guard |
| Service/API | Contract/parse tests for success/error/malformed | It has retry, pagination, cache or auth |
| Feature refactor | Characterization/regression before/after | It changes multiple components |
| Architecture migration | Contract parity + integration/regression + rollback | It changes persistence, session, auth, navigator |
| Performance | Comparable profiling before/after | The problem depends on device and scale |

## Example commands — always adjust to the repo

```bash
# Read-only / no source mutation
dart format --output=none --set-exit-if-changed lib test
# Pure-Dart package:
dart analyze
dart test # or a relevant existing test file

# Flutter package:
flutter analyze --no-pub
flutter test --no-pub test/features/orders/order_view_model_test.dart
flutter test --no-pub # if the scope justifies it and the tests exist

dart fix --dry-run # see proposed automatic changes; does NOT apply them
```

When passing subdirectories to `dart format`, pass only those that exist. `flutter test` and `flutter analyze` require a suitable SDK/dependencies; report if they are unavailable. The tools can create temporary build artifacts even if they do not change sources.

Include `bin` when CLI entry points are touched. Dependency preparation is a separate explicit step: Dart commands may resolve packages if missing; verify state before running them during a read-only audit. Use the project-selected SDK and do not install Flutter for Dart-only tests. A VM test does not verify browser JS/Wasm, platform signals or native interop. [Dart API examples](dart-evidence.md) provide controlled semantic checks without new dependencies.

## Characterization tests for refactors

1. Record the **real** behavior, including odd behaviors that are current contracts (if they are bugs, separate them).
2. Generate representative inputs and edge cases: empty, null, invalid, duplicate, retry, slow network, reverse order, cancellation/unmount.
3. Use deterministic fakes, not real requests or arbitrary sleeps where Futures/streams can be controlled.
4. Verify outputs and visible effects, not private method names or internal widget structure without need.
5. Only then change the design, keeping tests green; update tests only for approved contract changes.

## Do not hide regressions

- Do not introduce `skip`, mass lint suppression or mocks that remove the behavior under test.
- Distinguish **pre-existing failure**, **new failure**, **test not run**, **test not available**.
- When a golden fails, inspect the real render and the cause; do not regenerate it blindly.
- Analyze flaky tests for synchronization, clock, animations, mock dependencies and pending async.
- In CI, separate mandatory checks from the heuristic report (which can have false positives).

## Honest verification report

```text
Format: PASS — dart format --output=none --set-exit-if-changed lib test
Analyzer: PASS — flutter analyze
Tests: PASS — flutter test test/features/order_flow_test.dart
Integration: NOT RUN — requires browser/test credentials
Residual risk: history/back for route /orders not checked manually
```

Only print `PASS` if the agent ran the command and confirmed exit code 0.

## Targeted regression test for a bug fix

- Write the test that fails **before** the fix and passes **after**; run it both ways and report both results. A test that never failed proves nothing.
- Size it to the bug: one small test at the lowest layer that reproduces it. No new fixtures, harnesses or mocking frameworks for a small correction unless the existing ones cannot express the case.
- If the failure cannot be reproduced automatically, say so and record the manual scenario instead of inventing a test.
