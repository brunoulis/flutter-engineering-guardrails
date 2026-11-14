# Flutter code smell catalog: detector → decision → minimal refactor

**Note:** A smell **is not automatically a bug**. Check context, scope, cause and tests before intervening.

| Smell | Useful symptom | Minimal refactor | Verification / when to leave it |
|---|---|---|---|
| God widget | UI + I/O + validation + mutations + routes in one file | Extract pure rules or an existing VM per responsibility | Widget test and navigation contracts; if the file is long but cohesive, do not fragment it |
| `FutureBuilder` that recreates the future | Repeated requests during rebuild | Retain the future in lifecycle or move it to the VM | Count requests after `pump`/rebuild |
| Unnecessary global `setState()` | Local animation/filter invalidates the whole view | Move state to the owning subtree | DevTools before/after; do not assume jank |
| Giant `ChangeNotifier` | One notifier holds state from unrelated features | Split only states with distinct ownership | Listener/disposal tests; avoid cyclic coupling |
| `notifyListeners()` after dispose | Error on a late response | Cancel/discard the future; clear ownership | Open/close the screen before the request completes |
| Dual source of truth | Controller and VM hold a diverging mutable value | Choose a source and define synchronization | Form submit/reset/validation and navigation |
| 15-parameter constructor | Object handles disparate responsibilities | Group cohesive data or split responsibility if justified | Public API and tests; do not create an empty wrapper DTO |
| `Map<String,dynamic>` in every widget | Backend keys leak into the UI | Parse once on entering the data layer | Wrong payload, optional fields and expected cases |
| `!` everywhere | The code hides preconditions | Ensure invariant/explicit case | Test with null/incomplete data; `!` may be justified |
| `catch (_) {}` | Silent failure and broken UX | Error state + safe reporting/retry | Simulate failure and verify the UX response |
| Forgotten listener/controller | Closing the screen leaves observers alive | Owner's `dispose`/`removeListener` | Leak test/multiple mounts |
| Build with network calls | Repeated call on every rebuild | Move the side effect to lifecycle/VM with a contract | Verify requests and states |
| Mixed Navigation API | Inconsistent back stack | Gradually unify the affected routes | Deep links, back/forward, login guards |
| Repository per endpoint | Duplicated, ceremonial abstraction | Consolidate when coherent | Dependency changes do not break tests |
| Universal `BaseWidget/BaseUseCase` | Inheritance hides state/effects | Composition/concreteness as needed | Less navigation between files without losing reuse |
| Duplication in 2 places | Temptation toward a premature framework | Wait if they diverge semantically, extract if they change together | Test the shared rule; not DRY at any price |
| Magic variables/styles | Real visual inconsistency | Use existing theme/tokens | Screenshot/golden or UI review; do not extract every isolated number |
| Huge eager lists | Lag/memory with thousands of items | Lazy builders and pagination | Representative dataset and profiling |
| Missing `context.mounted` | Context used after await | Guard with the correct context + request control | Async and unmount test; mounted does not prevent stale results |
| Mock everything | Tests fragile to internal design | Contract fakes and effect tests | A harmless refactor should not break tests |

## Transformation patterns

### Extract pure rule

Use when there is a business rule that must be tested separately from Flutter. Avoid abstracting just because the block has more than N lines.

### Extract widget

Use when there is an independent visual responsibility, understandable prop boundaries or a significant local rebuild. Do not turn every `Padding` into a class.

### Introduce typed boundary

In the service/DTO when receiving JSON: validate structure explicitly and leave errors visible to the responsible layer. Migrate **endpoint by endpoint**, not every `Map` in the whole app in one PR.

### Replace temporary conditional with semantics

A cascade of ternaries for empty/loading/error can be turned into an explicit state or short methods. Do not force `sealed` if the SDK or style does not support it.

### Consolidate routing

Preserve the public routing API while migrating feature by feature, with an adapter if essential and a removal date. An isolated `Navigator.pop` does not require rewriting the whole router.

### Remove unnecessary abstraction

Detect classes with no state or contract that only delegate to another function. **Do not remove them automatically:** they may provide API stability, substitution in tests or real ownership.

## Stop the refactor if...

- There is no way to reproduce or characterize critical behavior.
- The change grows from a screen to the entire navigation/backend without justification.
- Tests pass because they have been disabled or their assertions weakened.
- The agent cannot explain which responsibility disappears and which is added.
- The only improvement is fewer lines or greater architectural "purity".
