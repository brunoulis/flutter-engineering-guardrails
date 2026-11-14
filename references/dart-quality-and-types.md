# Dart quality: precision, types and bounded complexity

Applies to Dart libraries, CLI tools and services as well as Flutter. Use [Effective Dart](https://dart.dev/effective-dart/design) and the project's actual SDK/language version. Companion guides: [async and I/O](dart-async-and-io.md), [sources and executable counterexamples](dart-evidence.md).

## Language and public API contracts

- Prefer `Object?` for genuinely untrusted values when operations must follow validation; reserve `dynamic` for boundaries that need dynamic dispatch. A cast describes an assumption, not a parser. Validate external shape, element types and domain constraints; do not coerce malformed values into plausible defaults silently.
- Records and patterns can simplify local data/shape handling. A matching map pattern can allow extra keys: explicitly decide whether unknown fields are permitted. Keep named domain types where invariants, documentation or API evolution justify them.
- A `final` variable cannot be rebound; the referenced object can still change. An unmodifiable list snapshot protects its own structure, not mutable nested elements. An `UnmodifiableListView` follows changes to the backing collection. Choose live view, shallow copy or immutable domain data according to the contract; do not claim deep immutability from `final` or a const constructor alone.
- Equality and `hashCode` must agree. Avoid mutating equality/hash-relevant state while an object is a map key or set member. Test aliasing and lookup behavior when changing value semantics.
- `_private` names are library-private, not class-private. An imported file is a separate library; a `part` belongs to the same library. Moving a helper can change accessibility. Do not expose a formerly private API merely to make extraction compile or introduce `part` as an automatic workaround.
- Choose `abstract`, `interface`, `base`, `final` and `sealed` from intended downstream construction/extension/implementation rights. Adding `final` or closing a hierarchy can break consumers and mocks; this is an API compatibility decision. Preserve exhaustive-switch behavior and test consumers when changing exported variants.
- An installed recent SDK does not automatically permit recent syntax in every package. Check the `environment.sdk` lower bound, language version and any `// @dart=` override before introducing records, patterns, class modifiers or newer syntax. Do not raise constraints simply to use a preferred style.

## Packages and non-UI applications

Preserve deliberate exports and entry points. `lib/src` is an implementation convention, not language-enforced privacy; avoid importing another package's internals. Do not create a class, interface, service or package for each function. Keep executable argument/I/O handling near `bin/`, reusable contracts in the existing library structure and deterministic logic independently testable.

For published libraries, a test with one lockfile does not prove the whole supported SDK/dependency range. Test lower-bound/consumer compatibility when relevant to the change, using an isolated resolution rather than downgrading the user's checkout. In a pub workspace inspect the shared lockfile and package configuration, overrides and affected member packages. Keep Flutter dependencies out of reusable pure-Dart code unless the API really requires them.

## Strong rules

- Use clear public types, `final` when there is no reassignment, invariants and null-safety; reduce `dynamic` at boundaries with external APIs.
- Do not "fix" null-safety with cascades of `!`, `as` or `late` when the invariant has not been proven. Validate explicitly before accessing.
- Do not use `catch (_){}` to hide errors; distinguish network error, timeout, parse, permission, validation, cancellation and programming error.
- Do not generate `toString()` to compare business states, nor JSON as a `Map` scattered across widgets.
- Put JSON ↔ model conversion at a tested boundary. Introduce models **according to value**, not one model per field.
- Avoid ambiguous boolean parameters, flags that change meaning and functions with mixed responsibilities; prefer names, types/options or separate methods if they clarify.
- Document **why**, preconditions and surprising decisions; do not repeat what the code already expresses.
- Respect existing style and lints; do not add a premium linter or incompatible rules without approval.

## Good use of Dart features

- `sealed class`, records, pattern matching and other modern capabilities **only if the project's minimum SDK supports them** and they simplify the design.
- For mutually exclusive states, choose between `enum` + data, typed variants, the `Result` pattern or the existing structure. Avoid impossible states such as `isLoading == true && hasError == true` if they matter semantically.
- For a simple result, do not create five generic classes if `Future<T?>` with an explicit contract handles the case well. For errors the consumer must display/recover from, consider a typed result.
- Prefer pure functions for deterministic transformations; they are good for unit tests.
- In hot loops, avoid unnecessary allocations/copies **after measuring**; do not trade readable code for theoretical micro-optimizations.

## Typed boundary example

Before (a caller assumes an external value has the right shape):

```dart
final name = response['client']['name'] as String;
```

After (illustrative; adapt to the real contract):

```dart
class Client {
  const Client({required this.name});
  final String name;

  factory Client.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String) {
      throw const FormatException('Expected client.name as String');
    }
    return Client(name: name);
  }
}
```

This factory checks `name` after a Map boundary has already been established; callers must still validate the decoded root. Decide separately whether blank names and unknown fields are valid. Parse at the input boundary and handle failures in the owning layer, not repeatedly in widget builds or downstream business functions.

## AI-generated anti-patterns

| Pattern | Why it usually makes things worse | Better approach |
|---|---|---|
| Generic `BaseRepository<T>` for a single CRUD | Fake API, complexity without benefit | Concrete service/repo until there is reuse |
| Five levels of widgets for a `Text` | Hinders reading and testing | Useful component with a clear contract |
| Extension/helper for every repeated line | Fragments the code | Accept trivial repetition or abstract real behavior |
| `try { ... } catch (_) { return null; }` | Erases causes and prevents diagnosis | Propagate a typed error, log safely or show feedback |
| `as dynamic` / `!` for convenience | Hides invalid contracts | Boundary validation and precise types |
| Tests that check internal implementation | Break with harmless refactors | Observable contracts and effects |
| "Optimizing" by changing the whole architecture | No causal relationship or measurement | Instrument, reproduce, change minimally and compare |

## Quality gate (before calling it done)

1. Can the flow be understood without navigating 8 files for a trivial action?
2. Do the name, type and access reflect the real responsibility?
3. Can the critical behavior be tested without starting the whole app?
4. Are there explicit failure and recovery paths?
5. Do the new abstractions reduce net complexity?
6. Is the code compatible with the project's Dart version?
