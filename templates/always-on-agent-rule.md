# Minimal project instruction for AGENTS.md, CLAUDE.md or Hermes

Insert the following text into **the agent's/project's own configuration** if you want the rules to persist without repeating the prompt in every task. It is optional.

---

For any Flutter/Dart change or review, use the `flutter-engineering-guardrails` skill. Load only the references relevant to the task. The source of truth is the code, the project's conventions and the `.flutter-rails.yaml` file (if present). In the absence of evidence, do not introduce new architecture, state management, libraries or packages. Prioritize correctness, resource ownership and disposal, regression tests, responsive/accessible UI, and small reversible changes. Use `audit` for diagnosis without modifications; `implement` for features; `refactor` for cleanup with preserved behavior; `deep-refactor` for justified migrations. Do not claim that tests were run or that performance improved without evidence.

---

**Note:** this is not a substitute for CI or hooks. If the skill is not installed/available to the agent, the agent must state the limitation instead of pretending it applied it.
