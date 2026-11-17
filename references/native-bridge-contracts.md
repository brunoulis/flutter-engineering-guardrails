# Native bridge contracts (Flutter ↔ Rust/C/C++/platform channels)

Load only when the app crosses a language boundary: `flutter_rust_bridge`, `dart:ffi`/ffigen, MethodChannel/EventChannel or Pigeon. Reuse this reference for the actual bridge; no additional bridge profile is required. A local fix must not turn into a cross-language migration. Review both sides when signatures **or semantics**, ordering, errors, ownership, encoding, build configuration or generator version change.

## When a shared contract or its generation inputs change

1. Find affected consumers on both sides (`rg` the symbol/channel name in native/Dart sources and generated files). Record behavior before → after, including semantics with unchanged signatures; inaccessible consumers stay UNVERIFIED.
2. Inspect generator inputs, configuration and selected version. Regenerate **when those changes require it**, including relevant semantic/encoding/configuration or generator-version changes even without a signature change; explain when regeneration is unnecessary. Use the project's selected/pinned generator version and review generated changes separately from hand-written code. Never hand-edit generated files or regenerate unrelated bindings.
3. Preserve released signature **and behavioral** compatibility, or explicitly authorize/version the migration when released apps may still send/receive messages.
4. Exercise a real consumer where required by risk; record which side was only inspected versus actually executed using the [verification matrix](testing-and-verification.md#verification-matrix). A mock-only Dart test does not establish native compatibility.

## Checklist

| Topic | Verify |
|---|---|
| Sync vs async | Locate the actual execution context and call cost. Blocking/CPU-heavy work must not stall the UI isolate or runtime; a Future-returning wrapper alone does not prove isolation. Keep work already safely isolated when it satisfies requirements. |
| Ownership | Who frees native memory/handles (`NativeFinalizer`, `dispose`/`close`); no use after free; no handle outliving its Dart owner. |
| Errors | Native errors/panics map to a typed Dart error; none is swallowed or crashes the process. |
| Types | Integer widths, nullability, enums, strings/encodings and optional fields match both sides; serialization test with a real sample, incl. missing/unknown fields. |
| Events/streams | Ordering, backpressure, cancellation and disconnect/reconnect; owner and awaited producer/listener shutdown, late callbacks and handles after cancellation. Timeout alone does not prove cancellation. Check event/log frequency and cost under [operational evidence](performance-and-web.md#operational-performance-not-only-benchmarks). |
| Platform | Each supported implementation exists or the call is guarded. Preserve feature-off/unsupported behavior or identify an authorized change; conditional imports and a different host OS are not execution evidence. |
| Release | Connect effective native dependency selection, target/flavor/features, build mode and built/bundled/loaded library identity to a real consumer. Debug or VM/widget tests do not prove a different Release DLL or installer. |

Report PASS/FAIL/UNVERIFIED/N/A with evidence and reasons; no language boundary in scope is justified N/A, without new infrastructure.
