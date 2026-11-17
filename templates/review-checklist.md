# Dart / Flutter PR / agent-generated code — review checklist

> Record PASS / FAIL / UNVERIFIED / N/A with evidence and reasons; do not check items automatically. Confidence and review disposition are separate from verification status.

Classify the package first. UI/state/navigation items are N/A for pure Dart; do not add Flutter dependencies or architecture to satisfy them.

## Dart language and runtime contracts
- [ ] Actual SDK, language version, resolved packages and matching documentation checked
- [ ] Public exports, subtype rights, errors and consumer compatibility preserved
- [ ] Input validation and alias/snapshot/equality semantics verified where changed
- [ ] Timeout, cancellation, stream ordering and owned shutdown distinguished
- [ ] CLI stdout/stderr/exit codes and process/file boundaries checked where applicable
- [ ] Native/browser assumptions verified on the relevant target, or marked unverified

## Correctness
- [ ] Acceptance criteria and edge cases defined
- [ ] Loading/empty/error/success paths as the flow requires
- [ ] No null assertions/casts without a precondition
- [ ] API/authorization contracts preserved

## Async, state and resources
- [ ] Owners of controllers/streams/timers are clear
- [ ] `dispose()`/removeListener/cancel where appropriate
- [ ] No UI updates on a disposed widget
- [ ] No stale responses or unintended double submit
- [ ] Single/coherent state, no business logic duplicated in the UI

## Design, platform and performance
- [ ] Existing breakpoints/Theme respected
- [ ] Zoom/text scaling/keyboard/semantics adequate
- [ ] No expensive I/O in `build()` nor huge eager builders
- [ ] No improvement claims without measurements

## Architecture
- [ ] Current state/routing pattern respected or migration justified
- [ ] Each new abstraction solves a concrete problem
- [ ] No dependency churn/no irrelevant codegen
- [ ] Package/feature separation only with net benefit

## Verification
- [ ] Base/candidate, dirty diff identity and compared range recorded; observed diff, inferred paths and exercised behavior distinguished
- [ ] [Regression Surface Report](../references/refactor-execution.md#regression-surface-report-required-output-for-implement-and-refactor) links each file/reason/behavior/consumer/evidence; state has owner and failure/cancel/shutdown closure
- [ ] Semantics/encoding/configuration/codegen reviewed even with unchanged signatures; actual [native consumer](../references/native-bridge-contracts.md) evidence or UNVERIFIED
- [ ] Feature-off/conditional/unsupported behavior preserved, authorized to change, or UNVERIFIED; no cross-platform inference
- [ ] Formatter/analyzer actually run (if available)
- [ ] Relevant tests/regressions actually selected/executed, names/counts and fails-before/passes-after evidence (or explicit limit); zero/all-skipped/stale logs do not establish behavior
- [ ] [Matrix](../references/testing-and-verification.md#verification-matrix) separates built/tested/integration/release with host OS, VM/widget/browser/device runtime, config/flavor/features, artifact identity and evidence freshness
- [ ] Pre-existing failures distinguished from new ones
- [ ] First solution/current candidate complexity and review dispositions linked under existing churn/triage; legitimate state remains justified
- [ ] Log/event activation, frequency, cost and platform checked; rare/throttled use and already-isolated work assessed in context
- [ ] Small changes; review and rollback feasible
- [ ] Explicit report of what was not checked, no invented "all OK"

Use equivalent compact prose and justified N/A for local low-risk changes. No new infrastructure or exhaustive matrix is needed for unaffected state/consumers/release. Audit mode remains read-only.
