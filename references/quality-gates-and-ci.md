# Automatic rails vs review: proportional quality gates

**Important:** `SKILL.md` gives instructions to the agent; it does not run checks automatically. To turn these policies into **enforcement**, the project must integrate CI/hooks/scripts with explicit authority. Never claim that the skill "guarantees" code quality.

## Level 1 — Fast feedback (during the task)

- Query concrete diagnostics from the IDE / Dart MCP if available.
- Analyze the affected file or feature and test the relevant logic.
- Run `dart fix --dry-run` only when there are lints/fixes to review.
- Avoid formatting/linting the whole repo in a hotfix that would produce thousands of lines of noise.

## Level 2 — Pull request (define in the repository's CI)

Example commands **to adapt**:

For a pure-Dart package:

```bash
dart format --output=none --set-exit-if-changed lib test
dart analyze
dart test
```

Include existing `bin` directories when relevant. Prepare dependencies explicitly under the repository's lockfile policy before claiming the audit is read-only. Use Flutter commands only for Flutter packages:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

The `--no-pub` option assumes dependencies have already been fetched; the pipeline can add a separate `flutter pub get` stage with cache/lockfile under its own policies.

When maintaining this skill's [async example](../examples/async_lifecycle/pubspec.yaml), a CI job with Flutter installed can run the following from the skill root. It covers controlled races, disposal and `FutureBuilder` ownership; it is not a check to impose on consuming apps.

```bash
cd examples/async_lifecycle
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

Exit codes differ: `dart analyze` fails on errors and warnings but not on *info* diagnostics by default (`--fatal-infos` to fail on them); `flutter analyze` also fails on *info* unless `--no-fatal-infos` is passed. Pick the behavior deliberately and document it in CI.

- A PR should be blocked by formatting failures, the configured strict analysis and relevant tests when the environment allows it.
- The audit tool and pattern searches for heuristic signals (see [refactor-audit](refactor-audit.md)) are **informative**, not an automatic blocking gate: they always exit 0 when a report is produced, and their leads need human confirmation. If a signal matters enough to block, prefer an analyzer lint that covers it.
- Do not publish "0 warnings" metrics if the corresponding set was not measured.

## Recommended lints

For pure Dart, use the existing compatible `package:lints` configuration; [`analysis_options_dart.yaml`](../templates/analysis_options_dart.yaml) is an optional starting point. Do not bring in `flutter_lints` or suppress legitimate CLI output just to reuse a UI template. Verify each proposed lint against the installed SDK and baseline.

[`../templates/analysis_options.yaml`](../templates/analysis_options.yaml) extends `flutter_lints` with lints that map to the guardrails: `avoid_void_async`, `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `unawaited_futures` and `avoid_dynamic_calls` (`flutter_lints` already provides `use_build_context_synchronously`, `avoid_print` and `empty_catches`). The strict typing modes are left as opt-in comments. Adopt it through the baseline process below, never as a silent drive-by change.

## Level 3 — Critical changes / release

- Contract tests for authentication, permissions, persistence, critical flows and errors.
- Widget/integration tests for routes and keyboard, web/desktop or mobile scenarios depending on targets.
- Observability and DevTools when there are performance or memory changes.
- Plan/feature flag/rollback for broad migrations.

## Baseline in legacy projects

1. Measure **existing** warnings/errors without modifying them.
2. Block the introduction of **new** errors in touched areas while gradually reducing the existing baseline.
3. Choose priority lints for correctness and maintainability, not to maximize the rule count.
4. Introduce new lints through a separate PR with justification and a previewed auto-fix (`dart fix --dry-run`).
5. Do not exclude all old code without leaving ownership and a review date.

## Review policy template

```text
For Dart/Flutter changes:
- The agent must apply flutter-engineering-guardrails.
- Changing state management, routing, packages or contracts in a local refactor without justification is forbidden.
- Large modifications require characterization tests and a slice plan.
- Before approval, CI must run format/analyze/test according to the type of change.
- Performance claims without measurement and invented tests are not accepted.
```

## CI test effectiveness (a green run is not proof tests ran)

- A filtered command (`flutter test --name`, `--plain-name`, a path with no tests) can exit 0 while running zero tests. For new regression tests, confirm the test count or name appears in the output, or that it fails when the fix is reverted.
- Map what CI actually covers: **built** (the target/flavor compiles), **tested** (which platform runs `flutter test`; web tests need `--platform chrome`), **integration** (`integration_test` on a device/emulator, not only widget tests), **release** (release/profile mode, obfuscation, `--split-debug-info`, minification for web) versus debug only. State each gap as `not run in CI`.
- Do not claim a platform is verified because another one passed; conditional code (`kIsWeb`, `Platform.isX`, conditional imports) needs a run on each side.

## Dependency and release integrity

- Apps: commit `pubspec.lock`; CI installs from it (`flutter pub get --enforce-lockfile` where supported). Libraries: do not commit it.
- Pin the Flutter version in CI (FVM, `flutter-version` or `.fvmrc`) and any code-generation tool versions; pin third-party GitHub Actions to a commit SHA.
- Every `dependency_overrides`, git dependency or forked/patched package carries a comment: why, upstream issue, and the condition for removing it.
- For shipped builds, keep a trace of what was built: resolved versions (`pubspec.lock`), build flags, and signing/notarization steps run. Never print signing keys or tokens in CI logs.
