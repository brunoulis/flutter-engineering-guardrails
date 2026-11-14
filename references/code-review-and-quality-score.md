# Adversarial Flutter code review and evidence-based assessment

## Review must not be limited to finding lint warnings

The reviewer acts as a maintainer: looking for *real errors and future cost*, not whether the AI followed an arbitrary style. If there are several valid solutions, explain the trade-offs instead of declaring the alternative "incorrect".

### Five passes

1. **Correctness:** contract, edge cases, null-safety, parsing, permissions, `Result`, possible states and invariants.
2. **Lifecycle and concurrency:** ownership/dispose, `await`, stale response, double tap, async navigation, recursion and streams.
3. **Architecture:** separation where it adds value, dependencies, significant duplication, single source of truth, "unnecessary abstraction".
4. **Experience and performance:** loading/error/empty, responsive, a11y, list builders, work in build, measurable jank.
5. **Tests and delivery:** regressions, boundary tests, analyzer, diff scope, rollback and documentation of decisions.

### Prioritized findings

Order by **P0 to P3** (defined in `refactor-audit.md`). For each finding include location, scenario, impact, minimal change and the test that would prove the fix. Do not fill a review with cosmetic issues if there is a serious error.

## Multidimensional quality (optional, not a magic number)

| Dimension | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Correctness/errors | Reproduced bugs left untreated | Critical paths without handling | Contract mostly covered | Contracts and edge cases verified |
| Async and lifecycle | Demonstrated leaks/races | Ambiguous ownership | Reasonable cleanup | Cleanup and races checked |
| Clarity/modularity | Unapproachable flow | Confusing dependencies | Readable responsibilities | Low net complexity and clear boundaries |
| Tests | Absent on critical paths | Happy path only | Important cases covered | Regressions and negatives checked |
| UI/a11y/responsive | Blocked flows | Visible fragility | Usable on targets | Edge cases checked |
| Performance | Serious measured problem | Unmeasured suspicion | No known problem | Adequate measurement and controlled regression |

**Scoring rules:** only assign 0–3 with concrete evidence per dimension; if there is no data write `N/E (not evaluated)`. Do not sum to "89/100", do not confuse impression with data, and do not compare repos using this table.

## Mandatory questions before approving a refactor

- Does the app behave the same before and after according to tests/characterization?
- Has complexity been reduced or just moved into more files?
- Do the new boundaries have a demonstrable single responsibility?
- Is the state/navigation choice consistent with the project?
- Will the user be able to maintain this without asking an AI to reconstruct the context of 15 layers?
- Is there anything that could be left **un**refactored for now?

## Useful code review comment

**Bad:** "Use Clean Architecture, split into 6 layers". 

**Good:** "In `lib/features/search/search_vm.dart:88`, call A can finish after B and overwrite the results. Reproduced with two completers; I propose checking the request ID before publishing state, without changing Provider". 

Use [`../templates/review-checklist.md`](../templates/review-checklist.md) as the final checklist when the change is large.
