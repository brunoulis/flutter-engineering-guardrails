# DEEP-REFACTOR mode — structural changes, with reversible migration

**Activated by evidence, not by size.** The user may request only the plan. Do not spontaneously implement a large migration.

## Qualitative activation thresholds

At least one of these arguments, backed by code/tests/incidents, must be strong:

- Coupling between features repeatedly blocks testing, deployments or changes.
- State/navigation with incompatible sources of truth and reproducible errors.
- Duplicated business logic causing functional divergence and high maintenance cost.
- Persistent, measured performance/memory problem with an identified cause.
- Unmaintained SDK or dependency that requires migration for compatibility or security.
- A component is practically impossible to modify safely despite local refactors.

**Not enough:** "the file has 700 lines", "Clean Architecture is better", "we want to use Riverpod", "everything should be Stateless". 

## Comparing options is mandatory

| Option | Benefit | Hidden cost / risk | When to choose |
|---|---|---|---|
| A. Keep + hotfix/test | Minimal change and fast delivery | May preserve debt | Urgent failure, little evidence for a redesign |
| B. In-place per-feature refactor | Migrates gradually and allows rollback | Temporary coexistence of patterns | Live project, many integrations |
| C. New bounded module/package | Clear boundaries, unit tests | Extra API/versioning/build | High cohesion and independent consumers |
| D. Rewrite one screen/feature | Cleans an isolated core | Risk of unknown cases | Bounded component with tests/contracts |
| E. Full rewrite | Coherent long-term architecture | Maximum regression, cost and timeline | Only with demonstrated scope, tests and superior benefits |

Never propose "E" without a functional/contractual inventory, real size, integrations, the cost of maintaining two apps and explicit acceptance from the owner.

## Strangler / slice migration

1. Map domains, routes, features and dependencies.
2. Select a non-critical but representative pilot feature.
3. Freeze contracts (schema, state, deep link, analytics, errors, UX, auth).
4. Create characterization tests and contract tests; identify incompatibilities.
5. Add a boundary/adapter **only** if it enables coexistence that is truly necessary.
6. Migrate the pilot feature and demonstrate parity; monitor crashes, timings, UI and support.
7. Expand feature by feature with **scheduled** removal of legacy code.
8. Remove temporary wrappers and flags once verified; document rollback.

## Design deliverables

- Lightweight ADR: problem, alternatives, decision and revocation condition.
- Simple diagram of current/target dependencies (not a giant decorative diagram).
- Table "contract → equivalence test → owner".
- Milestone plan: scope, acceptance criteria, risks, rollback.
- **Real** metrics (jank, memory, incidents, build duration, tests), if they exist. If they do not, design the measurement before optimizing.
- No-mixing policy: new patterns do not spread to every feature without justification.

## Packages and folders: adaptation, not obligation

The analogy with Rust's `Adaptive Crate Architecture` is an **adaptive feature/package architecture**. Extracting to a package requires a net benefit in isolation, contract, shared consumption or ownership. If a simple folder solves the problem well, keep the folder.

## Exit / rollback criteria

- A migrated feature passes success/error/state/back/responsive contract tests as applicable.
- No unexplained increase in crashes/regressions.
- The solution remains testable, documented and reversible.
- If a quality gate fails, stop the expansion and fix/revert; do not continue out of inertia.
