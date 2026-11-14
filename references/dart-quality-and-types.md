# Dart quality: precision, types and bounded complexity

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

Before (the UI depends on unvalidated server keys):

```dart
Text(response['client']['name'] ?? '')
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

Parsing should run when the data is fetched, with the error handled in the owning layer, not in every `build()`.

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
