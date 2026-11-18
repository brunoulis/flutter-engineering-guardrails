# Dart / Flutter Engineering Audit — [scope] / [date]

## Scope and verified facts
- Base and candidate revisions, dirty diff identity, compared range and existing local changes preserved (or no diff under audit):
- Observed inventory/exclusions versus inferred paths and actual execution; audited project remains read-only:
- Package kind (Dart library/CLI/service or Flutter), runtime targets and applicable sections; UI fields are N/A for Dart-only work:
- Package, main paths and platform(s):
- SDK/conventions, `analysis_options.yaml`, state/routing dependencies:
- Packages/plugins touched: exact resolved versions/sources, SDK/platform and evidence or discrepancies:
- Version-matched official documentation consulted (URLs or local paths), relevant API/default/deprecation facts:
- If updating: current → target, task justification, migration notes, SDK/native-platform compatibility, checks and rollback:
- Available tests and checks run (with output):
- Out of scope:

## Confirmed defects

Record each reachable failure once. If none was established, say so and summarize what was checked.

| ID | P0–P3 / confidence | File:line | Trigger/mechanism and consequence | Attribution (introduced / pre-existing / unknown) | Evidence | Minimal change / risk | Disposition and reason |
|---|---|---|---|---|---|---|---|

Use [review dispositions](../references/code-review-and-quality-score.md#triage-of-findings-from-another-agent-or-reviewer): corrected/verified, legitimate use, accepted in-scope limit, or investigation pending with question/evidence. A reviewer's severity label is not proof.

## Open leads

Include only material uncertainties. Name the missing evidence or the check that would settle each one. Exclude these from the confirmed count.

## Observed or proposed change surface

Use the existing [Regression Surface Report](../references/refactor-execution.md#regression-surface-report-required-output-for-implement-and-refactor); label proposed changes as proposals, not applied edits.

| Existing/new file | Why changed/proposed | Behavior/contract before → after | Affected consumer/path | Verification evidence or gap |
|---|---|---|---|---|

- Semantic contracts with unchanged signatures; affected scenarios/denominator if known, inferred versus exercised paths:
- New/changed state/resource → owner/mutator → reset/cancel/awaited close/dispose; necessity and failure/shutdown (or N/A with reason):
- Regression fails-before/passes-after evidence with both identities, or missing/unsafe reason; feature-off/conditional/unsupported target evidence or authorized change:
- First solution → current state/dependencies/abstractions/lifecycle and motivating review dispositions, using existing [churn control](../references/refactor-execution.md#churn-control-stop-the-fix-spiral); no invented revision history:

## Cross-cutting risks
- Public exports/subtyping, language version, input and collection ownership contracts:
- Async ordering, timeout/cancellation, resource shutdown and CLI/service I/O:
- State and resource ownership:
- Dependencies/boundaries:
- Navigation and backend contracts:
- Web/desktop/responsive:
- Privacy, errors and accessibility:

## Initial actions: 0–3 justified by findings
List only supported work: [Finding → goal → scope → test → rollback].
If none is justified, state that no changes are recommended.

## Not for now
- [Abstractions, migrations or cosmetic fixes without enough value]

## Verification and limits

Apply the [verification matrix](../references/testing-and-verification.md#verification-matrix); distinguish built, tested, integration and release, and host OS from actual runtime/target.

| Contract/scenario | Dimension (built / tested / integration / release) | Package/test kind, host OS, target/runtime, config/flavor/feature and artifact identity | Exact command/job | Selected / executed / passed / failed / skipped / disabled | Result (PASS/FAIL/UNVERIFIED/N/A), reason | Evidence location, date and candidate freshness |
|---|---|---|---|---|---|---|

- Partial coverage and required checks not run / reasons; unknown counts stay unknown and non-test counts are N/A:
- Distribution when relevant: effective versions/sources/overrides, built/bundled/loaded native library identity and consumer; connect debug-test and release identity or mark gap UNVERIFIED:
- Operational claims: activation, frequency, cost, platform and measurement/inference for logs/events/blocking; cancellation/shutdown evidence:
- Metrics not available:
- Residual risks / product decisions:

For a local low-risk audit/change use compact equivalent prose and justified N/A (e.g. no external consumer, state or release in scope); no extra infrastructure or runtime suite is required to fill fields.
