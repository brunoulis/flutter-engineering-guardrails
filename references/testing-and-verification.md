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

## Verification matrix

Use `PASS` (required check executed successfully for the identified candidate and scope), `FAIL` (observed failure), `UNVERIFIED` (missing, stale, conflicting or insufficient evidence), or `N/A` (outside this change, with reason). Confidence in a finding is separate from its verification status. Preserve a runner failure as FAIL while the unexercised contract remains UNVERIFIED. A successful exit alone is insufficient for a behavioral PASS.

| Contract/scenario | Dimension (built / tested / integration / release) | Package/test kind, host OS, target/runtime, config/flavor/feature and artifact identity | Exact command/job | Selected / executed / passed / failed / skipped / disabled | Result (PASS/FAIL/UNVERIFIED/N/A), reason | Evidence location, date and candidate freshness |
|---|---|---|---|---|---|---|

Identify base and candidate revisions (including dirty diff), actual Dart/Flutter SDK and effective dependency resolution. Link each log to that candidate, command and configuration; historical evidence can be reused only with a stated reason it still applies. Unknown counts stay unknown; non-test rows use N/A. Check selected names/counts and real execution, including all-skipped/disabled suites. Zero selected/executed tests, all-skipped tests, unavailable consumers and stale logs leave the contract UNVERIFIED; verify the runner/version's actual behavior rather than assuming every Flutter release handles empty selections alike.

Keep dimensions separate. The following are **illustrative unexecuted rows**, not results:

| Scenario | Dimension | Required distinction | Status without execution |
|---|---|---|---|
| Cancellation unit/widget test on Windows host | tested | Dart VM / Flutter test environment, exact SDK and debug test setup; no Windows native library implied | UNVERIFIED |
| Same conditional code in Chrome | tested | Browser runtime/renderer and actual `--platform chrome` selection; JS/Wasm configuration where applicable | UNVERIFIED |
| Plugin call on device or Windows desktop | integration | Actual device/desktop runtime, plugin implementation, loaded library identity and flavor/feature | UNVERIFIED |
| App build with feature disabled | built | Target, flavor, feature defines and compiler mode; build alone does not execute the disabled path | UNVERIFIED |
| Release DLL/app/installer | release | Built, bundled and runtime-loaded artifact identities, release flags and load/install smoke evidence | UNVERIFIED |

A widget test job hosted on Windows does not by itself exercise a Windows DLL or installer. A build does not prove integration, and debug tests do not validate a different release artifact. Record partial coverage and required outstanding checks explicitly. For a documentation-only/local change with no relevant distribution or runtime behavior, use compact justified N/A entries; do not run unrelated SDK suites.

## Targeted regression test for a bug fix

- Write the test that fails **before** the fix and passes **after**; run it both ways and report both results. A test that never failed proves nothing.
- Size it to the bug: one small test at the lowest layer that reproduces it. No new fixtures, harnesses or mocking frameworks for a small correction unless the existing ones cannot express the case.
- If the failure cannot be reproduced automatically, say so and record the manual scenario instead of inventing a test.
