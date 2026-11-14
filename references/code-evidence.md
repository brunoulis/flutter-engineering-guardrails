# Async safeguards: code evidence and limits

Use these cases when deciding whether a Flutter async flow needs a new safeguard. They support specific behaviors, not a judgment about an entire project's architecture. The linked revisions are fixed; check the target project's SDK and tests before relying on the same implementation.

## Duplicate submission: Compass Command

At `flutter/samples` commit `12a191622909214b516b0626fc1413be1000d12c`, [`Command._execute`](https://github.com/flutter/samples/blob/12a191622909214b516b0626fc1413be1000d12c/compass_app/app/lib/utils/command.dart#L50) returns immediately while `_running` is true and resets it in `finally`. The [`should only run once` test](https://github.com/flutter/samples/blob/12a191622909214b516b0626fc1413be1000d12c/compass_app/app/test/utils/command_test.dart) invokes the command repeatedly before awaiting completion and expects one action call.

- **Observed:** this instance excludes concurrent execution of its action. The source and test were inspected; the Compass suite was not run here.
- **Apply when:** a flow must reject duplicate submissions and already uses commands, or a command provides a useful ownership boundary.
- **Keep existing code when:** a local flag already implements that contract. Choosing not to introduce `Command` and `Result` is a review decision, not a result proved by the upstream test.
- **Limit:** this does not establish server idempotency or safe completion after the command is disposed.

## Obsolete completions: FutureBuilder

At `flutter/flutter` commit `e8ac49ab53c7a5db0c64f8d3664977de6c19f94b`, [`_FutureBuilderState`](https://github.com/flutter/flutter/blob/e8ac49ab53c7a5db0c64f8d3664977de6c19f94b/packages/flutter/lib/src/widgets/async.dart#L595) associates subscriptions with a callback identity. Reconfiguration and disposal invalidate it; success and error callbacks check it before updating the snapshot. The [transition-to-other-future test](https://github.com/flutter/flutter/blob/e8ac49ab53c7a5db0c64f8d3664977de6c19f94b/packages/flutter/test/widgets/async_test.dart#L144) replaces A with B, completes B before A and expects B.

- **Observed:** callbacks from the previous subscription cannot replace the current snapshot. The source and test were inspected; the full Flutter suite was not run here.
- **Apply when:** an async owner can receive obsolete results. The [local ViewModel](../examples/async_lifecycle/lib/search.dart) illustrates one generation-based implementation where the owner needs that protection.
- **Keep existing code when:** `FutureBuilder` already owns publication, or a state library provides an equivalent tested guarantee. The [local widget tests](../examples/async_lifecycle/test/future_builder_test.dart) exercise stale success/error and unmounting on the installed SDK without adding a second guard.
- **Limit:** ignoring callbacks does not cancel the future, undo remote mutations or guard writes in a separate ViewModel. `mounted` alone cannot distinguish two requests while the same widget remains mounted.

The [FutureBuilder API](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html) also requires obtaining the future before `build`; discarding obsolete callbacks does not solve repeatedly starting requests. Flutter's [architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations) are adaptable and make the domain layer conditional. Neither case justifies migrating an otherwise working state architecture.

## Controller replacement during build

The [TextEditingController API](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html) requires disposing an instance when it is no longer needed. If each build overwrites a field with a new controller, disposing the final field value does not release earlier instances or preserve their editing state. This is a consequence of that ownership flow; a syntax match alone does not prove a leak. The audit tool flags such replacements for inspection and keeps lazy field initialization with `??=` and immediate release-before-replacement as syntactic exceptions. Verify who owns each instance and whether rebuilding preserves the intended state.
