# Async, ownership, lifecycle and failure handling

## Resource inventory (mandatory when touching a stateful screen)

| Resource | Typical owner | Release / condition |
|---|---|---|
| `TextEditingController`, `FocusNode` | Form state, unless injected | `dispose()` if the instance is owned |
| `AnimationController`, `TabController` | `State` or owning object | `dispose()`; check `TickerProvider` |
| `ScrollController`, `PageController` | View that creates them | `dispose()` and callbacks when the widget changes |
| `StreamSubscription` | Service/notifier/State that subscribes | `cancel()` and a plan for stream errors |
| `Timer` (incl. periodic) | Component that creates it | `cancel()` before releasing dependencies |
| Listeners on `ChangeNotifier` | Object that calls `addListener` | `removeListener()` when it stops observing |
| HTTP Future | Use case/state that owns the request | Cancellation if the client allows it; otherwise prevent late effects |
| `ChangeNotifier` / Provider | Constructor or Provider scope | `dispose()` by the **creator**, not by each consumer |
| Isolate/event channel/IPC | Service that starts the channel | Orderly shutdown and disconnection handling |

Important: do **not** `dispose()` a controller received from outside if it belongs to another object. If a dependency the widget listens to changes, check `didUpdateWidget` and clean up/reassign listeners.

## Async: five common failures

1. **`setState` or use of `BuildContext` after `await`** without checking whether the widget is still mounted.
2. **Out-of-order responses**: request A starts, then B; B finishes first, but A overwrites its state.
3. **Double submission** of forms or duplicate navigation during loading.
4. **`FutureBuilder(future: fetch())`** created during rebuild, causing repeated requests.
5. **Discarded exceptions** with `catch (_) {}`, `print` and continuing in an invalid state.

`context.mounted` protects a context after the `await`, but it **does not prevent stale responses** nor cancel a request; these are different problems.

## Executable example: ViewModel with stale results

[SearchViewModel](../examples/async_lifecycle/lib/search.dart) publishes only the current request's result and stops publishing after disposal. It retains previous results during loading/error and exposes an immutable list snapshot. The repository and item are minimal example interfaces; adapt the UX and error mapping to the application. Callers must stop invoking the notifier once disposed.

[Unit tests](../examples/async_lifecycle/test/search_test.dart) use controlled Futures for stale success/error, loading while a newer request is pending, completion after disposal, snapshots and recovery. Run from `examples/async_lifecycle`:

```bash
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
```

This is one possible pattern. When `FutureBuilder` or the existing state library already owns and discards obsolete callbacks, preserve that mechanism. The [widget tests](../examples/async_lifecycle/test/future_builder_test.dart) exercise `FutureBuilder` directly without adding request IDs. These guards prevent late publication; they do not cancel remote work or protect side effects outside the guarded owner. See [pinned upstream evidence](code-evidence.md) for the scope of those guarantees.

## Meaningful error handling

- Distinguish **expected** failures (no connection, 401, timeout, resource 404) from **unexpected** failures (invalid JSON contract, bug, impossible state).
- A recoverable error should become a useful UX state with a safe retry where appropriate. Do **not** silently return incorrect data as if it were a success.
- Logs with enough technical context for diagnosis, without tokens, personal data or full confidential bodies.
- Do not automatically repeat/retry non-idempotent operations without protection against duplicates.
- The `Result<T>` pattern is optional, advisable when consumers must act according to failure classes; do not introduce it globally because of a single `try/catch`.
- Register unhandled errors through appropriate Flutter mechanisms (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) **only** if the project needs it and without duplicating reports.

## Race and lifecycle tests

1. Request A, then B, complete B and then A: the visible result must be B's.
2. Start an operation and remove the screen/notifier: no updates to already released objects.
3. Error response: defined state, message and recovery action.
4. Double tap on submit: do not duplicate actions if the business rules do not allow it.
5. Edit the parameters of a widget with a listener: old resource unsubscribed and new one listened to.
6. Leave and return to the screen: no ghost subscriptions or repeated requests.

Read: https://docs.flutter.dev/testing/errors and https://docs.flutter.dev/app-architecture/design-patterns/result.
