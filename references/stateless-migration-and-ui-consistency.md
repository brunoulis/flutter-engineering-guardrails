# StatefulWidget → StatelessWidget migration

Lessons from migrating screens, forms and dialogs of a Provider + `BaseViewModel` app to `StatelessWidget`. Load when the project rule is "screens, forms and dialogs are Stateless; mutable state lives in a viewmodel". For look and feel, see [ui-consistency](ui-consistency.md).

## Where each kind of State goes

| `State` member | Destination |
|---|---|
| `initState` + post-frame init, `_initializing` flag | Viewmodel `initializing` flag + idempotent `start()`/`initialize()` guarded by `_started`; the view calls it from a post-frame callback while `initializing` is true (`context.select`) and checks `context.mounted`. Always lower the flag in `finally`. |
| Message/snackbar callback registered in `initState` | Pass it to the viewmodel's `start(...)` once (idempotent). Use `context.mounted` instead of `mounted`. |
| `TextEditingController`, `ScrollController` | Viewmodel field, disposed in the viewmodel's `dispose`. Sync controller text from viewmodel state in a listener added in the constructor and removed before disposing controllers. |
| Local flags (`_obscure`, `_isFullScreen`, selected dropdown value) | Viewmodel field + method + `notifyListeners`. |
| Lists/labels the view kept in sync by hand | Derived getter on the viewmodel; delete the manual copy. |
| Stale-result guards (`_searchGeneration`, `_searchQuery`) | The viewmodel's own request sequence; the view only forwards. |
| `TabController` + `SingleTickerProviderStateMixin` | `DefaultTabController`. See "Tabs" below. |
| `FocusScopeNode` created per instance | Plain `FocusScope()`; it already owns a node per instance. |
| `AutoSizeGroup`, other pure objects with no lifecycle | Local variable in `build` (or in the helper that uses it, passed down). |
| Platform value loaded once (`PackageInfo`) | `static final Future` + `FutureBuilder`; a missing value renders empty. |
| State only for a dialog | Dialog-scoped viewmodel created by a `ChangeNotifierProvider` inside the dialog's own `build`, so call sites and tests keep constructing the same widget. |

Helper methods that used `State.context` need an explicit `BuildContext context` parameter (and any state they read, e.g. the viewmodel). Do the mechanical rename carefully: a regex applied to the whole file also rewrites methods of *other* classes defined later in the same file; re-read the diff.

Repeated paged/search dialogs (dates, fullscreen, scroll, load more) → one generic base viewmodel with `fetch`, `loaded`, `prepareSearch` hooks instead of N copies.

## Tabs

- Never disable the swipe/animation to make state easier (`NeverScrollableScrollPhysics`): it removes an existing behavior. Keep `TabBarView` default physics.
- To mirror the selected tab in a viewmodel without a `State`, wrap the content in `ListenableBuilder(listenable: DefaultTabController.of(context), ...)` and, if `viewModel.x != (tabs.index != n)`, schedule `toggle` in a post-frame callback. This follows both tap and swipe.
- Put the `DefaultTabController` **outside** any `Consumer` that can swap in a spinner, otherwise the selected tab resets after loading.
- If tab content is chosen by `AnimatedSwitcher`/`FadeTransition`, keep it and do not rebuild it with a different key strategy.

## Preserve UX

Animations, gestures and visual density must survive the migration; the checklist is in [ui-consistency](ui-consistency.md).

## Tests and baselines

- Fakes that `implements ViewModel` with `noSuchMethod` need every new getter/method the screen now reads (`initializing`, `start`, ...).
- Before blaming a failing test on the change, run it on the base commit in a temporary `git worktree add --detach <dir> <commit>` and remove the worktree afterwards. Report pre-existing failures as such.
- Never "restore" a file with `git checkout HEAD -- .` while there are uncommitted edits.
