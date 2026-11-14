# Widgets, state, forms, routing and responsive design

## Stateless ≠ superior; Stateful ≠ bad practice

The choice depends on **who owns and modifies the state**, not on dogma:

| Need | Reasonable candidate |
|---|---|
| Pure UI from parameters | `StatelessWidget` |
| `AnimationController`, `TextEditingController`, focus, tabs, ephemeral state | `StatefulWidget` with a clear lifecycle |
| Business state of a screen already managed with Provider/ViewModel | Consumer widget + existing ViewModel |
| Global state shared by several features | Already-established global pattern, with documented owner and scope |

Do not move a form that works with Provider/ViewModel to a `StatefulWidget` just to remove `notifyListeners`, and do not force every widget to be stateless when it needs its own resources.

## Reactive state and rebuilds

- Choose a single source of truth. Avoid duplicating `controller.text`, `selectedValue` and `viewModel.selectedValue` without defined synchronization.
- With Provider: observe in the widgets that need to update (`context.watch`, `Consumer` or `Selector` when it helps), access actions with `context.read` depending on the moment; respect the provider's scope.
- `ChangeNotifier`: notify observable transitions, not every statement; avoid a `notifyListeners()` after dispose using a disposed object.
- `setState`: for ephemeral state owned by `State` and when it affects a bounded subtree. Do not propagate invalidation to the whole screen for a local spinner.
- In Riverpod/BLoC, keep their specific convention; do not mix patterns to satisfy an agent preference.
- For forms: field validation, duplicate submission, disabled/loading states, focus, visible errors and preserving data on failure.

## UI structure

- `build()` must be a UI description without I/O, DB writes, automatic navigation or long non-memoized operations.
- Do not start a new async request on every rebuild; create and retain the Future/controller outside build when the semantics require it.
- Break widgets down by conceptual responsibility or rebuild region; do not extract trivial pieces because of length.
- Use `const` when it is valid and useful, not as a cosmetic obsession; do not override `Widget`'s `operator ==` to "optimize".
- Use `Key` when it gives stable identity (reorderable lists, preserved state, tests), not random keys on every build.

## Responsive Flutter Web and desktop

- Analyze constraints with `LayoutBuilder`, `MediaQuery` and flexible widgets according to context; base the layout on the container's available width when the screen is embedded.
- Do not invent common breakpoints or change an existing one without visual/product evidence.
- Test compact widths, breakpoint transitions, medium/wide widths, limited height, browser zoom and text scale.
- Avoid rigid widths and inaccessible content, overflows, conflicting nested scrolls and keyboard-related issues.
- `kIsWeb` detects the web runtime, **not** viewport width.
- For large tables/panels, choose scrolling/constraining/virtualization based on usability, not "shrink the font until it fits".

## Navigation

- Identify the main router and its guarantees: parameters, deep links, web history, back stack, guards and navigation after `await` operations.
- Mixing routing libraries without understanding the existing stack is prohibited; migrate only within a decided scope and with navigation tests.
- In async callbacks that use `BuildContext` after an `await`, check `context.mounted` where appropriate, and account for stale responses.

## Indicative UI test list

- Render: loading/error/empty/success and missing data.
- Events: tap, form submission, keyboard, selection, navigation and going back.
- Lifecycle: leaving the screen during a request, opening two requests, reloading, changing parent widget data.
- Adaptation: width before/after the breakpoint, scroll, text size and visible focus.
- Accessibility: names/semantics, navigation order, contrast and applicable interactive size.
