# Origin of the rules and limits of interpretation

## Dart language and non-UI applications

See [Dart sources, discussions and executable evidence](dart-evidence.md) for official language/package/API documentation, three r/dartlang threads and the SDK cancellation design discussion. They inform the Dart-specific routes for language contracts, libraries, CLI/services and async resources. The Flutter discussions below inform the additional UI/state/lifecycle guidance; they are not the sole basis of this skill.

## The three FlutterDev discussions

1. **AI is reducing my productivity** — https://www.reddit.com/r/FlutterDev/comments/1s9csar/ai_is_reducing_my_productivity/
   - Conflicting opinions on delegating programming versus keeping technical judgment.
   - Signals: generated code that looks correct but takes shortcuts, uncovered edge cases, poor abstractions and costly review.
   - Takeaway: design before implementing, require human review of contracts, risks and tests; do not let an agent replace the developer's understanding.
   - **It does not imply** that all AI worsens productivity; the comments are personal experiences, not controlled benchmarks.
2. **Flutter skills to make your AI agents smarter** — https://www.reddit.com/r/FlutterDev/comments/1raz7ry/flutter_skills_to_make_your_ai_agents_smarter/
   - Main shared link: https://playbooks.com/for/flutter. Its value is framed as specialized context for agents; it must not be treated as an authority above the SDK/documentation.
   - Takeaway: modular skills loaded on demand; verifiable context sources, not hallucinated APIs; use of official tools.
3. **Refactoring Extremely Bad Flutter Code** — https://www.reddit.com/r/FlutterDev/comments/18gz1o9/refactoring_extremely_bad_flutter_code/
   - Problems described: poorly managed state, mixed GetX/Navigator, controllers without dispose, unhandled errors, untyped `Map`, logic in widgets, few tests.
   - Repeated advice: do not rewrite without comparing costs; scope failures, formatter/lints, small changes/commits, regression tests, refactor by feature, document decisions and negotiate scope.
   - There are opposing opinions on rewriting; do not take one comment's vote as universal proof. Our rule is a **conditional decision**, not an absolute ban.

## Priority technical material

For concrete code and tests, see [async safeguards and counterexamples](code-evidence.md). Those pinned examples distinguish inspected behavior, local checks and review inferences.

- Agent Skills standard (frontmatter and structure): https://agentskills.io/specification
- Official Flutter Agent Plugins: https://github.com/flutter/agent-plugins
- Official Dart Skills: https://github.com/dart-lang/skills
- Flutter + Dart MCP and skills: https://docs.flutter.dev/ai/get-started and https://docs.flutter.dev/ai/tools
- Recommended, adaptable architecture: https://docs.flutter.dev/app-architecture/guide
- Unit/widget/integration tests: https://docs.flutter.dev/testing/overview
- Performance: https://docs.flutter.dev/perf/best-practices
- Error handling: https://docs.flutter.dev/testing/errors and https://docs.flutter.dev/app-architecture/design-patterns/result
- `dart fix --dry-run` and explicit application: https://dart.dev/tools/dart-fix
- `dart analyze`: https://dart.dev/tools/dart-analyze
- Accessibility: https://docs.flutter.dev/ui/accessibility

## Attribution principles

- The rules are an **original synthesis**; do not copy third-party threads or collections word for word.
- Prioritize current rules of the SDK/existing package over historical recommendations (the refactor thread dates from earlier years).
- No false benchmark claims, bugs "confirmed" by a regex, unverified code or "guaranteed bug-free".
- A green `flutter analyze` does not prove the absence of interface, data, concurrency or UX defects.
