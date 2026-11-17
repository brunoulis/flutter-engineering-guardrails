# Refactor plan — [feature/file]

**Mode:** refactor | deep-refactor
**Behavior change allowed:** NO (if YES, reclassify as feature/migration)

## 1. Need and evidence
- Base and candidate revisions, dirty diff identity, compared range and existing local changes preserved:
- Problem: [bug/duplication/coupling/ownership/UX/performance]
- Evidence with `path:line` or test/trace:
- Observable impact:
- Minimal measurable goal:

## 2. Preserved contracts
- Inputs / outputs:
- Loading/empty/error/success:
- Routes/back/deep links:
- API, serialization and persistence:
- Responsive/design/tokens/a11y:

## 3. Alternatives
| Option | Benefit | Risk | Decision |
|---|---|---|---|
| Do not modify yet | ... | ... | ... |
| Minimal in-place extraction | ... | ... | ... |
| Redesign feature/layer | ... | ... | ... |

## 4. Reversible slices
| Slice | Files | Isolated change | Prior test | PASS criterion | Rollback |
|---|---|---|---|---|---|
| 1 | ... | ... | ... | ... | ... |

## 5. Risk review
- Races/await/dispose/listeners:
- State/routing/provider scope:
- Data model/edge cases/errors:
- Web/desktop compatibility:
- New dependencies (justification):

## 6. Before → after
- Responsibilities removed:
- Responsibilities added:
- Net complexity and new classes:
- Debt still present by explicit decision:
- First solution → current candidate: added/removed state, dependencies, abstractions and lifecycle rules; motivating review findings/dispositions and why each addition remains necessary. Compare simplification/local/structural options under [existing churn control](../references/refactor-execution.md#churn-control-stop-the-fix-spiral); no invented history:

## 7. Tests run (facts only)

Use the [verification matrix](../references/testing-and-verification.md#verification-matrix). Include format/analyzer as applicable; built/tested/integration/release are separate dimensions, host OS is separate from actual runtime/target. Zero/all-skipped/stale evidence leaves behavior UNVERIFIED; runner failures remain FAIL.

| Contract/scenario | Dimension (built / tested / integration / release) | Package/test kind, host OS, target/runtime, config/flavor/feature and artifact identity | Exact command/job | Selected / executed / passed / failed / skipped / disabled | Result (PASS/FAIL/UNVERIFIED/N/A), reason | Evidence location, date and candidate freshness |
|---|---|---|---|---|---|---|

- Partial coverage/required checks outstanding; unknown counts stay unknown, non-test counts are N/A:
- Before/after metrics — measurements or UNMEASURED; log/event activation, frequency, cost and affected platform when relevant:
- Distribution if applicable: effective package/native resolution and overrides, built/bundled/loaded artifacts and real consumer; debug evidence does not establish different release identity. Otherwise justified N/A:

## 8. Regression surface

Fill the existing [Regression Surface Report](../references/refactor-execution.md#regression-surface-report-required-output-for-implement-and-refactor), distinguishing observed diff, inferred paths and exercised behavior.

| Existing/new file | Why changed | Behavior/contract before → after | Affected consumer/path | Verification evidence or gap |
|---|---|---|---|---|

- Public/semantic contracts affected even with unchanged signatures; [native consumers/codegen](../references/native-bridge-contracts.md) when applicable:
- New/changed state/resource → owner/mutator → invalidation/reset/cancel/awaited close/dispose; necessity and failure/shutdown (or justified N/A):
- Existing scenarios/denominator if established; inferred versus tested paths:
- Bug test fails-before/passes-after with both identities/evidence, or unavailable/unsafe reason and limit; characterization has a different objective:
- Feature-off, conditional imports and supported other platform/flavor: evidence, intentional authorized change, or UNVERIFIED:

## 9. Review and limits

| Finding/source and reviewed candidate | Trigger/consequence | Attribution (introduced / pre-existing / unknown) | Evidence/confidence | Disposition and reason |
|---|---|---|---|---|

Apply [review triage](../references/code-review-and-quality-score.md#triage-of-findings-from-another-agent-or-reviewer): corrected/verified, legitimate use, accepted in-scope limit, or investigation pending with question/evidence. Separate required unresolved checks from accepted limits; say when review was self-review/documentary only.

Keep local low-risk deliveries compact with equivalent slots and justified N/A. Do not add state, external consumers, release infrastructure or runtime suites solely to populate the plan.
