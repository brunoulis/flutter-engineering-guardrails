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

Order by **P0 to P3** (defined in `refactor-audit.md`). For each finding include location, trigger/mechanism and consequence, evidence/confidence, attribution (introduced / pre-existing / unknown), minimal change and the test that would prove the fix. A reviewer label alone establishes neither severity nor attribution. Distinguish observed diff, code inference and test/trace evidence. Pre-existing debt can be serious without becoming a regression or requiring unrelated scope expansion.

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

## Anti-Slop Score (tool, `--score`)

Evidence only; each dimension lists its items and is graded independently. Do not sum, average or compare repositories.

| Dimension | Evidence counted | Deliberately **not** counted |
|---|---|---|
| duplication | function/method bodies of >= 60 tokens equal after renaming identifiers (literals kept) | similar-looking widgets with different content |
| complexity | functions with cyclomatic complexity > 15 (`copyWith` excluded: one `??` per field) | file length, widget nesting, number of widgets |
| mixed-responsibilities | widgets using Dio/HttpClient/SharedPreferences/jsonDecode directly; view models using `BuildContext`/Navigator/dialogs | classes that are merely long |
| useless-layers | classes with >= 2 methods that all forward 1:1 to one field and implement no contract | layers the project mandates (repository contract + impl) |
| dependencies | `pubspec.yaml` `dependencies` never imported from lib/bin/test | plugin-only or config-only packages need manual verification |
| tests | logic classes (ViewModel/Repository/DataSource/Service/UseCase) whose file no test imports | actual coverage: an import is not coverage |

Grade: 3 = no items, 2 = 1-2, 1 = 3-9, 0 = 10+, `N/E` = nothing to measure. The bands only let a report be compared with itself over time. Treat every item as a lead (see "confirmed / probable / heuristic").

## Triage of findings from another agent or reviewer

Do not accept every finding another agent produced. For each one, before changing code:

1. **Reproduce** it (test, command, trace) or mark it UNVERIFIED with the missing evidence/question. Record the reviewer/source and candidate reviewed; repeated review is not evidence by itself.
2. **Own it:** does the defect belong to this change, or was it already there? Pre-existing defects are reported separately, not folded into the diff.
3. **Cost the fix:** what else does the suggested change alter? A fix that breaks working behavior is worse than the finding.
4. Record a disposition with evidence: **corrected/verified**, **legitimate use**, **accepted in-scope limit**, or **investigation pending** with the open question and next evidence. A rejected finding needs a reason; a deferred finding needs its limit/owner or tracking reference. “Not reproduced” is not “refuted”. Silence is not a verdict.

Link dispositions to the [Regression Surface Report and revision evolution](refactor-execution.md#regression-surface-report-required-output-for-implement-and-refactor). New state justified by a real contract is valid; flags patching prior flags require reconsideration rather than automatic rejection by LOC. State unresolved required checks separately from accepted limits and use the [verification statuses](testing-and-verification.md#verification-matrix). Say when review was only self-review/documentary inspection; do not imply independent execution.
