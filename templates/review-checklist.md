# Flutter PR / agent-generated code — review checklist

> Mark YES / NO / N/A with evidence; do not check items automatically.

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
- [ ] Formatter/analyzer actually run (if available)
- [ ] Relevant unit/widget tests and regressions
- [ ] Pre-existing failures distinguished from new ones
- [ ] Small changes; review and rollback feasible
- [ ] Explicit report of what was not checked, no invented "all OK"
