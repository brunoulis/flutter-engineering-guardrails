# UI consistency with the app's existing design

Load when adding or changing a screen, dialog or component, and after any migration that could alter visuals (see [stateless migration](stateless-migration-and-ui-consistency.md) for state).

## Match siblings, not Flutter defaults

- Before writing UI, find a sibling screen or component that does the same job and copy its structure, sizes, colors and typography. Use the project's tokens (`AppColors`, theme text styles), not new literals.
- A default widget often looks out of place. Example in this app: compact tab bars use `SizedBox(height: 28)` with a green indicator (`AppColors.green.shade400`), `AppColors.textColor(context)` for the selected label, `AppColors.grey.shade500` for unselected and `fontSize: 13`; a bare `TabBar` (48 px) is visibly too tall.
- When a screen diverges from the rest (admin tabs were too tall), fix it with the same component settings used elsewhere; if the same block is repeated in 3+ places, say so and propose a shared widget instead of a fourth copy.

## Preserve UX through refactors

A refactor keeps animations, gestures, focus behavior and visual density.

- Never disable swipe or animations to simplify state (`NeverScrollableScrollPhysics` on a `TabBarView` removed an existing behavior).
- Keep `AnimatedSwitcher`/`FadeTransition`/Lottie loaders and their keys.
- Grep the diff for added or removed `physics`, `Animated*`, `*Transition`, `Duration`, `Curve`, `Lottie` and confirm each is intentional.
- To verify an animation, pump mid-transition (`pump(Duration(milliseconds: 100))`) and read opacities/positions, on the base commit and on the new one. A widget test does not measure the tab indicator slide or real frame timing; say what was not checked.

## Check

Open the screen in light and dark themes and at narrow widths when possible; report honestly if the app was not run.
