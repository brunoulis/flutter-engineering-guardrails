# Dart sources, discussions and executable evidence

Research checked on 2026-11-14. Official API pages consulted reported Dart **3.14.0**, matching the installed SDK. Version-specific API URLs were unavailable through the browsing tool, so the async/list contracts were also checked in the installed SDK's `lib/async/future.dart`, `lib/async/stream.dart`, `lib/core/list.dart` and `lib/collection/list.dart`. Online URLs below can move: reapply R0a for a different project/version. These observations are not a mandate to upgrade.

## Official sources and the decisions they support

| Source | Use in this skill |
|---|---|
| [Effective Dart: Design](https://dart.dev/effective-dart/design) | Intentional public types and abstraction boundaries; avoid ceremonial classes. |
| [Patterns](https://dart.dev/language/pattern-types), [Object.hashCode](https://api.dart.dev/dart-core/Object/hashCode.html) | Shape matching is not all domain validation; equality and hashing must agree. |
| [Variables](https://dart.dev/language/variables), [List.unmodifiable](https://api.dart.dev/dart-core/List/List.unmodifiable.html), [UnmodifiableListView](https://api.dart.dev/dart-collection/UnmodifiableListView-class.html) | Binding, snapshot, live view and nested mutability are different contracts. |
| [Libraries and imports](https://dart.dev/language/libraries), [class modifiers for API maintainers](https://dart.dev/language/class-modifiers-for-apis) | File extraction can cross a privacy boundary; modifier changes can break downstream users. |
| [Language versioning](https://dart.dev/language/versioning), [creating packages](https://dart.dev/tools/pub/create-packages), [pub workspaces](https://dart.dev/tools/pub/workspaces) | Check package language version, exports and shared resolution rather than just the executable SDK. |
| [Future.timeout](https://api.dart.dev/dart-async/Future/timeout.html), [Future.wait](https://api.dart.dev/dart-async/Future/wait.html), [unawaited](https://api.dart.dev/dart-async/unawaited.html) | Waiting, completion, errors and cancellation require different decisions. |
| [Stream.listen](https://api.dart.dev/dart-async/Stream/listen.html), [asyncMap](https://api.dart.dev/dart-async/Stream/asyncMap.html), [subscription cancel](https://api.dart.dev/dart-async/StreamSubscription/cancel.html), [pause](https://api.dart.dev/dart-async/StreamSubscription/pause.html) | Async callbacks, serial conversion, buffering and asynchronous resource cleanup. |
| [Concurrency](https://dart.dev/language/concurrency), [Process](https://api.dart.dev/dart-io/Process-class.html) | Distinguish event-loop work, native isolates, browser constraints and subprocess I/O. |
| [Package dependencies](https://dart.dev/tools/pub/dependencies) | Test compatibility claims across supported dependency versions; keep resolution experiments isolated. |

## Threads: reported problems, not universal rules

1. [Am I using Async the wrong way?](https://www.reddit.com/r/dartlang/comments/1109eqk/) (r/dartlang, 2023): the author expected an async initializer to avoid a CPU pause. This motivates checking the event-loop model. The official concurrency guide supports that distinction; it does not prove the reported app needs a worker isolate or a Flutter-specific helper.
2. [Const objects](https://www.reddit.com/r/dartlang/comments/r8spde/) (r/dartlang, 2021): a final parameter still permits mutation of the referenced object. Use it as an aliasing/ownership counterexample, not as support for claims that `final`, an annotation or a const constructor deeply freezes arbitrary runtime objects.
3. [Add Future#cancel, SDK #1806](https://github.com/dart-lang/sdk/issues/1806) (historical design discussion, opened 2012): maintainers distinguish suppressing callbacks from cooperation by the underlying operation. Current Future APIs and local tests establish the specific timeout/wait behavior; historical snippets are not drop-in modern code.
4. [Handling client disconnects on HttpServer](https://www.reddit.com/r/dartlang/comments/1qa9z35/handling_client_disconnects_on_httpserver/) (r/dartlang, 2026): the author reports a stalled paused response and a timeout workaround. Retain pause/disconnect/shutdown as test scenarios. The report was **not reproduced here**; neither its network explanations nor socket workaround become a general rule.

These are original reports/design discussions used to identify questions. Technical guidance rests on official contracts and local observations, not vote counts or popularity. No third-party examples have been copied into the tests.

## Executable checks

[`tool/test/dart_semantics_test.dart`](../tool/test/dart_semantics_test.dart) has ten SDK behavior tests: mutable final binding; snapshot versus view; shallow unmodifiable list; timeout followed by an effect; eager error followed by sibling completion; late successful cleanup; unawaited error propagation; overlapping async listeners; sequential asyncMap; awaited cancellation cleanup.

Run from `tool/`, using the existing locked `package:test` dependency (1.33.0 in this evidence run):

```sh
dart pub get --enforce-lockfile
dart test test/dart_semantics_test.dart
```

These tests run without Flutter imports and are included in `dart test` and repository CI. They demonstrate the listed API semantics on the tested SDK. They do **not** add detector rules, reproduce the HTTP report, benchmark isolates, verify browser behavior or certify an arbitrary Dart application. See [contribution checks](../CONTRIBUTING.md) for the complete suite.
