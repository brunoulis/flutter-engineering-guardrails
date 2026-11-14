# Dart async, resource ownership and I/O

Use for Dart libraries, CLI tools and services, and the non-UI parts of Flutter. Apply R0a first: these API contracts were checked with Dart 3.14.0; match the target SDK/package rather than assuming a current example applies. [Sources and executable counterexamples](dart-evidence.md).

## Futures: identify what actually stops

- An `async` function does not offload CPU work. Work between suspension points occupies the current isolate. Profile before choosing chunking or an isolate; do not insert arbitrary delays as a synchronization protocol.
- `Future.timeout` limits waiting for a result. The original operation can still finish and produce side effects. Cancel through the underlying operation's documented mechanism, or guard late effects where owned; do not promise to undo a remote write.
- `Future.wait(eagerError: true)` reports the first error early; it does not cancel siblings. A small fixed batch can be appropriate. An unbounded input needs an explicit concurrency/resource budget, not an automatic ban on `Future.wait`.
- `Future.wait`'s `cleanUp` handles successful non-null results when the group fails, including late successes. It is a synchronous callback, must not throw and is not an awaited async shutdown protocol. Track asynchronous cleanup separately when required.
- `unawaited` expresses deliberate non-waiting, not exception handling. A detached task still needs a responsible error handler and a lifetime/shutdown policy. Keep `Future<void>` when callers must observe completion; preserve required `void` callback signatures and handle async work deliberately inside them.
- Preserve error and stack information (`rethrow` when propagating from a catch); catch expected failures where recovery is possible. Neither `catch (_) {}` nor a generic fallback value proves recovery.

## Streams: delivery, processing and cleanup are separate

`stream.listen((event) async { ... })` does not wait for each callback's Future. Later callbacks can overlap, stream `onDone` can precede task completion, and errors from those Futures need their own handling. If order is required, use `await for` with an awaited body or `asyncMap`; if overlap is intentional, bound it and join owned work during shutdown. Avoid replacing an already-correct sequential flow with a worker framework.

Distinguish single-subscription and broadcast contracts. Pausing a subscription may buffer events rather than slow the producer; `asyncMap` serializes conversion but does not guarantee end-to-end backpressure or bounded memory. Inspect the actual source, buffering, loss/replay and consumer lifetime before changing to broadcast, caching a stream or adding a queue.

The owner cancels subscriptions and timers, closes sinks/controllers and awaits required cleanup. `StreamSubscription.cancel()` returns the cleanup Future; await it before dependent actions such as deleting the source file. Cancellation does not automatically join async callbacks already started. Test paused streams, errors, early exit and shutdown, not only successful exhaustion.

## CLI and service boundaries

- Keep parsing and business logic testable without starting a process. Preserve the CLI's documented stdout data, stderr diagnostics and exit codes; help/usage, malformed input and operational failure need explicit contracts.
- Await owned shutdown in `finally` or the existing lifecycle mechanism. Handle signals only on supported targets; do not call immediate process exit before required writes/cleanup finish. Do not close a caller-owned sink/client.
- For subprocesses, pass program and argument list separately; avoid shell evaluation of user input. With `Process.start`, consume stdout and stderr while awaiting exit so pipe buffers do not block completion. Test nonzero exit, malformed output and cancellation using a controlled local child process when this boundary changes.
- Keep paths distinct from URIs; use the existing path abstraction/package after checking its version. Test path/platform behavior where relevant. Avoid synchronous I/O in a latency-sensitive request loop; a short synchronous CLI setup step is not automatically a defect.
- For services, bound request bodies, queued work, concurrency and idle lifetimes according to the protocol. A report about a paused HTTP connection is a test scenario, not proof of an SDK bug or justification for detaching sockets/replacing HTTP.

## Isolates and runtime boundaries

Native isolates have separate state and communicate through messages. Check sendability, closure captures, transfer/startup costs, worker errors and shutdown before moving work. An isolate is useful for measured CPU pressure, not a universal cure for asynchronous I/O.

Check native VM/AOT versus browser JavaScript/Wasm targets. Native isolate APIs and `dart:io` are not a portable browser strategy; web workers have different setup and messaging constraints. Use appropriate conditional imports/adapters and verify the target build. Do not infer browser support from a passing VM test or add Flutter's `compute` to a pure-Dart package.

## Focused verification

Use Completers and controlled streams to test ordering, cancellation/timeout effects, errors and shutdown. Verify resource ownership with real observable cleanup. For concurrent work, measure the maximum active operations and test failure while siblings are pending. Keep network/browser/device checks separate when not actually run.
