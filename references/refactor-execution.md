# REFACTOR mode — safe transformation through vertical slices

## Definition

A refactor **preserves observable behavior**. If UX, API, persistence, navigation, permissions, response structure or business effect changes, that is a **functional change or migration**, and it must be labeled as such.

For package-dependent cleanup or updates, apply **SKILL.md R0a** first: verify the resolved package and actual SDK versions and consult their corresponding documentation. Do not replace working APIs merely to follow newer examples. For an authorized update, compare current/target documentation and migration notes, separate it from unrelated cleanup, and verify SDK, plugin/platform and observable UI/lifecycle compatibility.

## The 9-step protocol

1. **Scope:** function/widget/feature and exact contract; identify constraints and off-limits files.
2. **Characterize:** capture existing tests, golden/manual scenarios and known errors. A test that was already failing is reported, not attributed to the refactor.
3. **Dependencies and ownership:** draw the `UI → ViewModel → repository/service → API` flow; locate routes, sessions, timers, listeners, models.
4. **Choose a single intent:** logic extraction, typing one response, splitting a widget, lifecycle, or migrating one route. Do not combine intents without need.
5. **Small change:** keep the API; optionally introduce an adapter; separate mechanical formatting into its own diff.
6. **Local verification:** formatter/analyzer + the affected test and two failure paths; add regression tests for bugs found.
7. **Adversarial review:** what can break if the network changes, the screen is destroyed, there are two requests, or parsing fails?
8. **Comparison:** responsibilities/differences before/after, debt removed, debt deferred, cost of new abstractions.
9. **Rollback:** a simple diff or manual restoration, a feature flag if it crosses systems; no `git commit` without permission.

## Five highest-value refactors

**A. UI ↔ logic:** extract a rule that needs tests out of `build()` into the existing ViewModel/pure function. Keep callbacks/controller; do not introduce extra layers without reason.

**B. Gradual typing at boundaries:** convert one API response at a time from `Map<String, dynamic>` to a model with validation. Add tests for missing payload, null, unexpected type and success. Do not change the whole network layer at once.

**C. Stateful and lifecycle:** identify ownership of controllers/streams/listeners, close them in dispose, handle `didUpdateWidget` and out-of-order responses. Test destroying/recreating.

**D. Large widgets:** extract components by UI cohesion, clear inputs and rebuild areas; not "one widget per line". Compare visibility/constraints before and after.

**E. Routing:** gradually centralize navigation in the established stack. Test entering, going back, deep link, nested screen and web history before removing the old API.

## Recommended order for messy legacy code

1. Record a baseline of warnings and failures.
2. Separate purely mechanical changes (formatting/lints) **only if the resulting diff is reviewable**. Preview `dart fix --dry-run`; limit `--apply` to agreed rules/areas.
3. Fix concrete failures and create regression tests.
4. Extract logic/state in features that are actually being edited.
5. Improve integration and repeat. Rewriting individual screens inside the app can be valid if it lowers overall risk and cost.

Never hide CI errors with blanket `// ignore_for_file`, `dynamic`, empty `try/catch` or mass `skip:`. One-off exceptions need a reason and a ticket/review date.

## Example: a useful but small refactor

Before (inside the UI callback):

```dart
onPressed: () {
  final total = products.fold<double>(0, (sum, p) => sum + p.price);
  if (total > 100) {
    showDiscount();
  }
}
```

After, if the discount rule is business logic that repeats and needs tests:

```dart
bool qualifiesForDiscount(Iterable<Product> products) {
  final total = products.fold<double>(0, (sum, p) => sum + p.price);
  return total > 100;
}
```

The UI still runs `showDiscount()` only if the function returns true. Test the 100 boundary, 100.01, an empty iterable and relevant products. **If the rule is unique and trivial, leaving it where it is may also be better.**

Use the template [`../templates/refactor-plan.md`](../templates/refactor-plan.md).
