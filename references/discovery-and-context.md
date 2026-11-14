# Repository discovery before modifying Dart or Flutter code

**Goal:** get a concrete snapshot of the existing code; the agent must not replace it with its own preferences.

## 1. Minimal inspection (read-only, no destructive effects)

First identify the affected package (or workspace member), whether it uses Flutter, and whether the deliverable is a library, CLI, service or app. From that package's root:

```bash
git status --short
git branch --show-current
rg --files -g pubspec.yaml -g pubspec.lock -g pubspec_overrides.yaml -g analysis_options.yaml
dart --version
rg --files lib bin test integration_test # pass only existing directories
```

Inspect `environment`, `workspace`, `resolution`, dependency overrides, resolved package metadata and any library language-version overrides. For a workspace, also inspect the shared resolution at its root. A Dart-only package needs no Flutter tooling. Only for a Flutter package, add:

```bash
flutter --version
rg -n 'provider:|flutter_bloc:|riverpod:|get:|go_router:|auto_route:' pubspec.yaml
rg -n 'class .*ViewModel|extends ChangeNotifier|Consumer<|context.watch|BlocBuilder|ref.watch' lib
rg -n 'Navigator\.|Get\.(to|back|off)|GoRouter|context\.go\(' lib
```

- In a monorepo, identify the task's **package** instead of assuming the root is an app.
- The commands above are **examples**: if `rg`, `flutter` or `git` are missing, fall back to equivalent tools and record it.
- Do not mix in generated files (`*.g.dart`, `*.freezed.dart`), checkout, lockfile or automatic migrations unless explicitly needed.
- Do not read or publish `.env` files, secrets, keys or credentials unless the task requires it.

## 2. Minimal context map

Collect only what is relevant; mark UI/navigation rows N/A for Dart-only work:

| Aspect | Question |
|---|---|
| Package/runtime | Dart library, CLI/service or Flutter app? VM/AOT, browser JS/Wasm, supported OS? |
| SDK | Actual Dart SDK, package/library language version; Flutter SDK only where relevant |
| API and I/O | Public exports/modifiers, input validation, stdout/stderr/exit codes, file/process/network boundaries? |
| Async/resources | Ordering, timeout versus cancellation, owned tasks, streams/sinks and awaited shutdown? |
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
