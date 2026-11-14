# Flutter Engineering Guardrails

A portable agent skill for **writing, auditing and refactoring Flutter/Dart code** with engineering discipline, without imposing an architecture the project does not use. Inspired by the approach of `rust-engineering-guardrails`, three technical discussion threads on r/FlutterDev, and the official Flutter/Dart guides.

## Contents

- `SKILL.md`: main policy, modes and reference routing (loads only what the task needs, to save tokens).
- `references/`: 15 focused guides (discovery, adaptable architecture, widgets/state, errors and resources, refactors, migrations, performance, testing, security/a11y, scoring and sources).
- `templates/`: project convention profile, audit report, refactor plan, review checklist, prompts, and a suggested `analysis_options.yaml`.

There is no bundled binary or script. The skill drives the official Dart/Flutter tooling directly: `dart format`, `dart analyze` / `flutter analyze`, `flutter test`, `dart fix --dry-run`, the analyzer lints, and the Dart/Flutter MCP server when it is installed.

## Installation

The root of this repository **is** the skill folder (it contains `SKILL.md`). Installing it means placing this folder, named `flutter-engineering-guardrails`, in your agent's skills directory. Replace `<repository-url>` with this repository's URL.

### Requirements

| For | You need |
|---|---|
| Using the skill (instructions and references) | Only the agent: Claude Code, Codex or Hermes Agent. Plus `git` to clone |
| Letting the agent check the project (`dart format`, `analyze`, tests) | Flutter/Dart SDK on the `PATH` |
| Code search for heuristic signals (recommended) | [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) on the `PATH`; see [Install ripgrep](#install-ripgrep). Without it, the agent falls back to `git grep` |
| Richer diagnostics (optional) | The Dart/Flutter MCP server |

### Where the skill goes for each agent

| Agent | Personal (all your projects) | Project (versioned with the repo) |
|---|---|---|
| Claude Code | `~/.claude/skills/flutter-engineering-guardrails/` | `<project>/.claude/skills/flutter-engineering-guardrails/` |
| Codex | `~/.agents/skills/flutter-engineering-guardrails/` | `<project>/.agents/skills/flutter-engineering-guardrails/` |
| Hermes Agent | `~/.hermes/skills/flutter-engineering-guardrails/` | `<project>/.hermes/skills/flutter-engineering-guardrails/` or `<project>/.agents/skills/…` |

On Windows, `~` is your user folder (`$HOME` in PowerShell, e.g. `C:\Users\<user>`).

### Claude Code

macOS / Linux:

```bash
# Personal
git clone <repository-url> ~/.claude/skills/flutter-engineering-guardrails

# Or per project (from the project root)
git clone <repository-url> .claude/skills/flutter-engineering-guardrails
```

Windows (PowerShell):

```powershell
# Personal
git clone <repository-url> "$HOME\.claude\skills\flutter-engineering-guardrails"

# Or per project (from the project root)
git clone <repository-url> ".claude\skills\flutter-engineering-guardrails"
```

Claude Code picks up new skills without a restart. If the `skills` directory did not exist when the session started, run `/reload-skills`. To invoke it manually: `/flutter-engineering-guardrails`.

### Codex

macOS / Linux:

```bash
# Personal
git clone <repository-url> ~/.agents/skills/flutter-engineering-guardrails

# Or per project (from the project root)
git clone <repository-url> .agents/skills/flutter-engineering-guardrails
```

Windows (PowerShell):

```powershell
# Personal
git clone <repository-url> "$HOME\.agents\skills\flutter-engineering-guardrails"

# Or per project (from the project root)
git clone <repository-url> ".agents\skills\flutter-engineering-guardrails"
```

Codex detects new skills automatically; if it does not show up, restart Codex. To check: `/skills`, or mention it with `$flutter-engineering-guardrails`.

### Hermes Agent

macOS / Linux:

```bash
# Personal
git clone <repository-url> ~/.hermes/skills/flutter-engineering-guardrails

# Or per project (from the project root)
git clone <repository-url> .hermes/skills/flutter-engineering-guardrails
```

Windows (PowerShell):

```powershell
# Personal
git clone <repository-url> "$HOME\.hermes\skills\flutter-engineering-guardrails"

# Or per project (from the project root)
git clone <repository-url> ".hermes\skills\flutter-engineering-guardrails"
```

Project skills are only loaded once you trust the repository: run `hermes skills trust` at its root. To check: `hermes skills list`.

### One copy for several agents

Clone the skill once and link it from each agent's directory, so a single `git pull` updates all of them.

macOS / Linux:

```bash
git clone <repository-url> ~/skills/flutter-engineering-guardrails
mkdir -p ~/.claude/skills ~/.agents/skills ~/.hermes/skills
ln -s ~/skills/flutter-engineering-guardrails ~/.claude/skills/flutter-engineering-guardrails
ln -s ~/skills/flutter-engineering-guardrails ~/.agents/skills/flutter-engineering-guardrails
ln -s ~/skills/flutter-engineering-guardrails ~/.hermes/skills/flutter-engineering-guardrails
```

Windows (PowerShell; junctions do not need administrator rights):

```powershell
git clone <repository-url> "$HOME\skills\flutter-engineering-guardrails"
foreach ($dir in ".claude", ".agents", ".hermes") {
  New-Item -ItemType Directory -Force "$HOME\$dir\skills" | Out-Null
  New-Item -ItemType Junction -Path "$HOME\$dir\skills\flutter-engineering-guardrails" -Target "$HOME\skills\flutter-engineering-guardrails" | Out-Null
}
```

### Install ripgrep

The audit searches in `references/refactor-audit.md` are written for `rg`. Install it once per machine, together with the skill:

| Platform | Command |
|---|---|
| Windows | `winget install --id BurntSushi.ripgrep.MSVC --exact` (or `choco install ripgrep`, or `scoop install ripgrep`) |
| macOS | `brew install ripgrep` |
| Debian / Ubuntu | `sudo apt install ripgrep` |
| Fedora | `sudo dnf install ripgrep` |
| Arch | `sudo pacman -S ripgrep` |

Then check it from a **new** terminal (on Windows, winget updates the `PATH` only for shells opened after the install, so restart the agent too if it was running):

```bash
rg --version
```

Other platforms and prebuilt binaries: [ripgrep installation guide](https://github.com/BurntSushi/ripgrep#installation). Some agents bundle their own search tool; installing `rg` still matters because the skill's commands run in the agent's shell.

### Update and uninstall

- **Update:** `git pull` inside the skill folder. There is nothing to build.
- **Uninstall:** delete the `flutter-engineering-guardrails` folder from the skills directory, or the link if you used a single copy.

Agent paths may change between versions. Official docs: [Claude Code](https://code.claude.com/docs/en/skills), [Codex](https://learn.chatgpt.com/docs/build-skills), [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/).

## Usage

In the agent:

- "Use `flutter-engineering-guardrails` in **audit** mode to review this project. Do not modify code."
- "**implement** mode: add the new screen following our Provider/ViewModel setup."
- "**refactor** mode: improve this screen without changing its behavior; write tests first."
- "**deep-refactor** mode: compare extracting features, adding layers, or leaving it as is. I want the analysis first."

The checks the agent runs are the same ones you can run yourself from the root of any Flutter project:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
dart fix --dry-run
```

`flutter analyze` exits non-zero even when there are only *info* diagnostics (use `--no-fatal-infos` to change that); `dart analyze` does not fail on infos by default. Read the output before concluding there are errors. None of these commands modify source files; the skill never runs `git commit`, `dart fix --apply` or `flutter pub upgrade` on its own.

To get the guardrails' static checks from the analyzer itself, merge [`templates/analysis_options.yaml`](templates/analysis_options.yaml) into your project's `analysis_options.yaml`. It extends `flutter_lints` with `avoid_void_async`, `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `unawaited_futures` and `avoid_dynamic_calls`. On an existing project, measure the current baseline first (see `references/quality-gates-and-ci.md`).

Patterns no lint covers (undisposed controllers, `Timer.periodic`, `FutureBuilder` futures created in `build`, `setState(() async`, file-wide suppressions, mixed navigation APIs, large files) are found with `rg` (or `git grep` as a fallback); the patterns are in `references/refactor-audit.md`. For example:

```bash
rg -n --type dart -g '!*.g.dart' -g '!*.freezed.dart' 'Timer\.periodic\(' lib
```

Search hits are **heuristic leads**, not confirmed bugs.

To keep these rules active in every review, copy the block in `templates/always-on-agent-rule.md` into `AGENTS.md`, `CLAUDE.md` or the equivalent configuration. For CI, see `references/quality-gates-and-ci.md`.

## Project profile

Copy `templates/project-profile.yaml` to your project root as `.flutter-rails.yaml` and adapt its values. It is a **contract readable by humans and agents**: no tool reads or enforces it automatically. It takes precedence over this skill's generic recommendations, except for security/correctness issues.

The example profile describes an existing Flutter Web app with Provider/ViewModel and a legacy responsive breakpoint, for illustration. Replace those values with your project's real ones.

## Philosophy

**Rails to prevent mistakes, not rails to impose style:** correctness, security, lifecycle and tests are hard constraints; architecture, number of layers, widget types and folder structure are decided with evidence.

See `references/sources-and-rationale.md` for where the recommendations come from, attributions and limits.

## Validation

**2026-11-14, Windows x64, Flutter 3.50 / Dart 3.14:** the lints in `templates/analysis_options.yaml` resolve with no unknown-rule warnings and each fires on a probe file that reproduces the old Rust scanner's rules; the search patterns in `references/refactor-audit.md` match the remaining cases on the same file with both ripgrep 15.2.0 and `git grep`, and skip generated files.

## License

MIT. See [`LICENSE`](LICENSE).
