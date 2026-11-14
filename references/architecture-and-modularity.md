# Adaptive architecture: structure by need, not by fashion

The official Flutter guide describes UI (views/ViewModels) and data (repositories/services) as a **recommended but adaptable** architecture, with an optional domain layer. See https://docs.flutter.dev/app-architecture/guide.

## First: does it really need a new abstraction?

| Observed symptom | Candidate minimal solution | Escalate to another layer only if... |
|---|---|---|
| Simple local calculation | Pure method or Dart helper | It repeats significantly or requires complex independent tests |
| Single-view form | Local state / existing ViewModel | There are shared rules, complex cancellation/validation or cross-screen state |
| One-off HTTP call | Existing client/service + model if it is a boundary | There is caching, multiple sources, reconciliation or domain contracts |
| Data read by several screens | Existing repository or notifier | There is loading state, caching, permissions or cross-feature consistency |
| New self-contained feature | Feature folder with UI and logic | There are stable dependencies and APIs that justify an internal package |
| Files too large | Extract by responsibility and testability | Length alone is **not** enough for new packages |

## Adaptive decision matrix

1. **Keep as is** if the code is small, understandable, testable and rarely changes. Do not demand OOP where a pure function is better.
2. **Extract method/helper** if it reduces branching, improves naming or avoids real duplication.
3. **Extract widget** if it delimits a visual responsibility, state/rebuild or semantic reuse. Prefer clear components over a cascade of builder functions that hide dependencies.
4. **Separate ViewModel / service / repository** when a boundary brings testability, side-effect management, caching, typing or a well-defined responsibility. Do not create all three layers for every endpoint.
5. **Extract feature/package/workspace** only when internal cohesion is high, dependencies between modules are controlled, there is independent reuse/ownership, or a publishing/build boundary adds measurable value.

An example structure (NOT mandatory):

```text
lib/
  app/                        # composition root, routing, theme
  features/
    orders/
      presentation/           # existing views/widgets/viewmodels
      data/                   # repos/services only if they add value
      models/                 # contracts, invariants
  shared/                     # little, only proven reuse
```

## State and dependency

- **Ownership:** Who instantiates the state, who listens to it, when is it destroyed?
- **Scope:** local state vs. feature/flow vs. global session. Do not lift everything into a singleton.
- **Direction:** UI may depend on data contracts; services should not couple to `BuildContext`, routes or widgets for convenience.
- **Injection:** constructor or existing Provider, enough to substitute dependencies in tests. Do not demand an external DI container if it adds no value.
- **Immutability:** preserve snapshots and avoid hidden mutations that do not notify.
- **Routes:** keep one main system; a mix can be valid as a documented transition, but do not introduce a third library.

## Package separation criteria

Evaluate first: real number of consumers, API stability, lifecycle/versioning, Flutter dependencies, build times, import/CI complexity and circular coupling. Do **not** create packages to gain the appearance of Clean Architecture.

**Anti-hybrid rule:** if a state/routing pattern is being migrated, define the per-feature order, adapters and removal of the old layer. Do not leave perpetual mixes without an owner.

## Small decision record

```text
Decision: keep Provider + ViewModel for this feature.
Evidence: it appears in neighboring screens and there are tests with that interface.
Alternatives: local setState, Riverpod, BLoC.
Why: shared state in this flow; migrating a framework does not reduce the task's risk.
Cost: one ChangeNotifier and its test; we do not add an extra use-case/repo.
Revisit if: coupling makes testing harder or duplicated logic reappears.
```
