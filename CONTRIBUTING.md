# Contributing — validate Dart contracts and Flutter behavior

Contributions should help agents preserve Dart language/API, async and I/O contracts, and Flutter UI behavior and lifecycle. Keep the audit tool in Dart under `tool/` and use `package:analyzer` for structural inspection. Do not replace the project's architecture, state library or official analyzer with a blanket style policy. Pure-Dart packages must remain usable without Flutter.

## Start with the actual SDK and packages

Read [SKILL.md](SKILL.md), the relevant reference, `tool/pubspec.yaml` and its lockfile. Apply **R0a** before using, cleaning or updating a library: verify the resolved package and actual Flutter/Dart SDK versions, then consult corresponding official documentation.

For an update, compare current/target docs and migration notes, SDK constraints, transitive dependencies, code generators and affected native plugins/platform requirements. Explain the need, keep unrelated packages unchanged and review lockfile/native configuration changes. Cleanup alone does not justify `pub upgrade` or a state/routing migration.

The tool requires Dart **3.13+** within its declared constraint. CI uses Flutter **3.50.0**, including Dart **3.14.0**, for the tool and Flutter example. That pinned baseline does not establish compatibility with every supported SDK or mobile device.

## Proposing a guardrail or detector change

1. Reproduce a concrete lifecycle, async, layout or correctness problem. Record SDK/package versions and the platform or widget scenario that triggers it.
2. Include similar valid code: constructor-injected controllers, properly disposed resources, cached futures, bounded work and legitimate navigation choices need counterexamples.
3. Decide whether an existing analyzer lint already covers the problem. Add a custom rule only where the tool provides useful additional evidence.
4. Add positive/negative tests in `tool/test/rules_test.dart`. Use `tool/test/cli_test.dart` for scope, diagnostics, output and exit changes. Observe the relevant regression fail before implementing the fix.
5. Keep findings heuristic where types or cross-file ownership are unresolved. AST structure is not proof of a leak or an instruction to dispose a resource owned by someone else.
6. For actual async/lifecycle advice, use executable widget/state examples such as `examples/async_lifecycle/`. Test stale success/error completion and disposal rather than only matching generated text.
7. Document scope, false positives, unsupported cases, behavior compatibility and rollback; obtain skeptical independent review for substantive changes.

For Dart language/API guidance, consult the matching SDK docs and preserve runnable counterexamples such as `tool/test/dart_semantics_test.dart`. Those tests exercise real SDK semantics, not custom detector coverage. Cover public API/subtype compatibility, malformed input, aliases, ordering, failure and cleanup according to the change; no Flutter widget scaffold is needed for a pure-Dart contract. Community threads suggest scenarios, but current official contracts and reproduction determine technical claims.

Guidance changes should be tried against a realistic task. Preserve existing conventions and distinguish behavior-preserving cleanup from a UI/API migration. Small prose fixes need focused document/link review.

## Local checks

Run from this repository's root, using the project's intended SDK. Dependency preparation below is explicit and writes only the tool/example dependency state and the package cache; it does not upgrade an audited application.

```sh
cd tool
dart pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed bin lib test
dart analyze
dart test
cd ../examples/async_lifecycle
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
cd ../..
```

For an intentional dependency update, regenerate and inspect the relevant lockfile as part of that change, then rerun the enforced-lockfile checks. Do not drop the enforcement flag merely to make CI pass. Check formatting of changed example Dart code with the installed SDK; do not mix a blanket formatter migration into unrelated work.

[CI](.github/workflows/skill-ci.yml) runs the tool checks and the Flutter example on Linux, macOS and Windows with the same pinned SDK. Host widget tests are not Android/iOS integration tests, a web deployment check or a proof of device-specific behavior. Report those checks separately when a contribution affects them.

`dart test` includes the ten [Dart semantics checks](references/dart-evidence.md) alongside detector/CLI tests. They use the existing locked test dependency and need no Flutter imports. The workflow uses Flutter's bundled Dart for convenience; the `tool/` package itself has no Flutter SDK dependency.

## Safety and review evidence

- Auditing must not change target code, run `dart fix --apply`, upgrade target packages, or execute code from comments/configuration.
- Keep target/path validation, generated-source handling, explicit output writes and syntax diagnostics covered by CLI tests. Missing or incomplete analysis must remain visible.
- Do not weaken analyzer settings, skip failing tests, regenerate goldens blindly or suppress legitimate warnings to claim success.
- Preserve report/exit contracts, or document the migration. A successfully produced heuristic report is not certification of lifecycle safety.
- Keep fixtures minimal, retain provenance/licenses for upstream examples, and leave caches, builds, credentials and external corpus checkouts out of contributions.

A useful PR states the triggering behavior and smallest fix, a valid counterexample, versions/docs consulted, actual commands/results and skips, affected platforms, false-positive limits, compatibility/rollback and reviewer outcome. Preserve the existing [license](LICENSE) and third-party notices.

Workflow setup references: [Flutter action](https://github.com/subosito/flutter-action), [locked pub resolution](https://dart.dev/tools/pub/cmd/pub-get#enforce-lockfile) and [checkout action](https://github.com/actions/checkout). External actions are pinned by commit; SDK/action changes require reviewed compatibility evidence.
