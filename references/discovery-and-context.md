# Repository discovery before modifying Flutter code

**Goal:** get a concrete snapshot of the existing code; the agent must not replace it with its own preferences.

## 1. Minimal inspection (read-only, no destructive effects)

From the root of the correct Flutter package:

```bash
git status --short
git branch --show-current
find . -maxdepth 3 \( -name pubspec.yaml -o -name analysis_options.yaml \) -print
flutter --version             # if available
rg -n 'provider:|flutter_bloc:|riverpod:|get:|go_router:|auto_route:' pubspec.yaml
rg -n 'class .*ViewModel|extends ChangeNotifier|Consumer<|context.watch|BlocBuilder|ref.watch' lib
rg -n 'Navigator\.|Get\.(to|back|off)|GoRouter|context\.go\(' lib
find test integration_test -type f -name '*.dart' 2>/dev/null | wc -l
```

- In a monorepo, identify the task's **package** instead of assuming the root is an app.
- The commands above are **examples**: if `rg`, `flutter` or `git` are missing, fall back to equivalent tools and record it.
- Do not mix in generated files (`*.g.dart`, `*.freezed.dart`), checkout, lockfile or automatic migrations unless explicitly needed.
- Do not read or publish `.env` files, secrets, keys or credentials unless the task requires it.

## 2. Minimal context map

Collect only what is relevant:

| Aspect | Question |
|---|---|
| SDK | Dart/Flutter supported by `pubspec.yaml`; capabilities actually available |
| State | Local, shared within a feature, or app-wide? Who creates and destroys it? |
| UI | Theme/Design System, reusable widget, text, localization, responsive? |
| Network and data | Where is JSON serialized/validated? HTTP errors, auth, cache? |
| Navigation | A main router, deep links, back stack, guards? |
| Tests | Current tests, manual scenarios, flaky tests, real coverage? |
| Platform | Web, Windows/macOS/Linux, Android/iOS, relevant sizes |
| Release | Deadline constraints, compatibility, flags, critical flows |

Code evidence is `path:line` plus observed behavior; **do not** invent results from running code that is not available.

## 3. Contracts and change budget

Make explicit before acting:

- Inputs/outputs, loading, empty states, errors, retries, affected screens and routes.
- Public behavior that **cannot** change.
- External dependencies, observability and integration boundaries.
- Maximum scope: hotfix, small refactor, feature, major migration.
- How to roll back: an isolated change, a validated toggle, or restoring a reviewed diff.

If the request is small, the inspection must be small too. Fixing a `TextField` does not require reading every feature or producing an architecture document.

## 4. Progressive context discovery

- Look at the exact files first; then importers and relevant tests.
- Read `.flutter-rails.yaml` if it exists; **do not generate or modify it on your own initiative**.
- Use Graphify or another index only if it is installed and helps with a real navigation problem; do not build graphs by default.
- Load only the reference module relevant to the task (see the table in `SKILL.md`).
- Separate facts, hypotheses and preferences: "uses Provider" is a fact; "we should migrate to Riverpod" is a hypothesis that needs evaluation.
