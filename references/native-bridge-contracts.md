# Native bridge contracts (Flutter ↔ Rust/C/C++/platform channels)

Load only when the app crosses a language boundary: `flutter_rust_bridge`, `dart:ffi`/ffigen, MethodChannel/EventChannel or Pigeon. A local fix must not turn into a cross-language migration, but a change to a shared signature must be checked on both sides.

## When you change a shared function, struct or message

1. Find every consumer on the other side (`rg` the symbol/channel name in the native sources and generated files) and list them.
2. Regenerate bindings only when the signature changed, with the project's pinned generator version, and review the generated diff separately from hand-written code. Never hand-edit generated files.
3. Keep the old signature working or version the message when released apps may still send/receive it.

## Checklist

| Topic | Verify |
|---|---|
| Sync vs async | Blocking native calls never run on the UI isolate; heavy ones are async or in an isolate. |
| Ownership | Who frees native memory/handles (`NativeFinalizer`, `dispose`/`close`); no use after free; no handle outliving its Dart owner. |
| Errors | Native errors/panics map to a typed Dart error; none is swallowed or crashes the process. |
| Types | Integer widths, nullability, enums, strings/encodings and optional fields match both sides; serialization test with a real sample, incl. missing/unknown fields. |
| Events/streams | Ordering, backpressure, cancellation and what happens on disconnect/reconnect; the stream is closed when the Dart listener goes away. |
| Platform | Each platform's implementation exists or the call is guarded; unsupported platforms fail with a clear error. |
| Release | Native library is bundled and loads in release builds, not only in debug. |

Report which side was actually exercised by a test and which was only read.
