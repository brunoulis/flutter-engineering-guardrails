# Flutter Engineering Guardrails

Skill portable para **generar, auditar y refactorizar código Flutter/Dart** con criterios de ingeniería y sin imponer arquitecturas ajenas al proyecto. Inspirada en el enfoque de `rust-engineering-guardrails`, el debate técnico de tres hilos de r/FlutterDev y las guías oficiales de Flutter/Dart.

## Contenido

- `SKILL.md`: política principal, modos y enrutamiento de referencias para ahorrar tokens.
- `references/`: 15 guías especializadas (análisis previo, arquitectura adaptable, widgets/estado, errores y recursos, refactors, migraciones, rendimiento, pruebas, seguridad/a11y, puntuación y fuentes).
- `templates/`: perfil de convenciones del proyecto, informe de auditoría, plan de refactor, checklist de review y prompts.
- `rust/src/bin/audit.rs`: escáner heurístico de solo lectura escrito en Rust, compilable sin crates externos.
- `rust/src/bin/check.rs`: ejecutor de formato/análisis/pruebas (Rust, sin crates externos).
- `rust/`: crate con pruebas unitarias de Rust (`cargo test`).

## Instalación

La raíz de este repositorio **es** la carpeta de la skill (contiene `SKILL.md`). Instalarla consiste en dejar esta carpeta, con el nombre `flutter-engineering-guardrails`, en el directorio de skills de tu agente. Sustituye `<url-del-repositorio>` por la URL de este repositorio.

### Requisitos

| Para | Necesitas |
|---|---|
| Usar la skill (instrucciones y referencias) | Solo el agente: Claude Code, Codex o Hermes Agent. Y `git` para clonar |
| Que el agente compruebe el proyecto (`dart format`, `analyze`, tests) | Flutter/Dart SDK en el `PATH` |
| Las herramientas opcionales `flutter-rails-audit` y `flutter-rails-check` | Rust 1.96 o superior con Cargo ([rustup](https://rustup.rs); comprueba tu versión con `rustc --version` y actualiza con `rustup update stable`). En **Windows**, además, Visual Studio Build Tools con la carga de trabajo «Desarrollo para el escritorio con C++» (el enlazador de Rust para MSVC). En **macOS**, `xcode-select --install`. En **Linux**, un compilador de C (`build-essential` o equivalente) |

### Dónde va la skill en cada agente

| Agente | Personal (todos tus proyectos) | De proyecto (se versiona con el repo) |
|---|---|---|
| Claude Code | `~/.claude/skills/flutter-engineering-guardrails/` | `<proyecto>/.claude/skills/flutter-engineering-guardrails/` |
| Codex | `~/.agents/skills/flutter-engineering-guardrails/` | `<proyecto>/.agents/skills/flutter-engineering-guardrails/` |
| Hermes Agent | `~/.hermes/skills/flutter-engineering-guardrails/` | `<proyecto>/.hermes/skills/flutter-engineering-guardrails/` o `<proyecto>/.agents/skills/…` |

En Windows, `~` es tu carpeta de usuario (`$HOME` en PowerShell, por ejemplo `C:\Users\<usuario>`).

### Claude Code

macOS / Linux:

```bash
# Personal
git clone <url-del-repositorio> ~/.claude/skills/flutter-engineering-guardrails

# O de proyecto (desde la raíz del proyecto)
git clone <url-del-repositorio> .claude/skills/flutter-engineering-guardrails
```

Windows (PowerShell):

```powershell
# Personal
git clone <url-del-repositorio> "$HOME\.claude\skills\flutter-engineering-guardrails"

# O de proyecto (desde la raíz del proyecto)
git clone <url-del-repositorio> ".claude\skills\flutter-engineering-guardrails"
```

Claude Code detecta las skills nuevas sin reiniciar. Si el directorio `skills` no existía al abrir la sesión, ejecuta `/reload-skills`. Para invocarla a mano: `/flutter-engineering-guardrails`.

### Codex

macOS / Linux:

```bash
# Personal
git clone <url-del-repositorio> ~/.agents/skills/flutter-engineering-guardrails

# O de proyecto (desde la raíz del proyecto)
git clone <url-del-repositorio> .agents/skills/flutter-engineering-guardrails
```

Windows (PowerShell):

```powershell
# Personal
git clone <url-del-repositorio> "$HOME\.agents\skills\flutter-engineering-guardrails"

# O de proyecto (desde la raíz del proyecto)
git clone <url-del-repositorio> ".agents\skills\flutter-engineering-guardrails"
```

Codex detecta las skills nuevas automáticamente; si no aparece, reinicia Codex. Para comprobarla: `/skills`, o mencionarla con `$flutter-engineering-guardrails`.

### Hermes Agent

macOS / Linux:

```bash
# Personal
git clone <url-del-repositorio> ~/.hermes/skills/flutter-engineering-guardrails

# O de proyecto (desde la raíz del proyecto)
git clone <url-del-repositorio> .hermes/skills/flutter-engineering-guardrails
```

Windows (PowerShell):

```powershell
# Personal
git clone <url-del-repositorio> "$HOME\.hermes\skills\flutter-engineering-guardrails"

# O de proyecto (desde la raíz del proyecto)
git clone <url-del-repositorio> ".hermes\skills\flutter-engineering-guardrails"
```

Las skills de proyecto solo se cargan cuando confías en el repositorio: ejecuta `hermes skills trust` en su raíz. Para comprobarla: `hermes skills list`.

### Una sola copia para varios agentes

Clona la skill una vez y enlázala desde el directorio de cada agente. Así un `git pull` la actualiza en todos.

macOS / Linux:

```bash
git clone <url-del-repositorio> ~/skills/flutter-engineering-guardrails
mkdir -p ~/.claude/skills ~/.agents/skills ~/.hermes/skills
ln -s ~/skills/flutter-engineering-guardrails ~/.claude/skills/flutter-engineering-guardrails
ln -s ~/skills/flutter-engineering-guardrails ~/.agents/skills/flutter-engineering-guardrails
ln -s ~/skills/flutter-engineering-guardrails ~/.hermes/skills/flutter-engineering-guardrails
```

Windows (PowerShell; las *junctions* no necesitan permisos de administrador):

```powershell
git clone <url-del-repositorio> "$HOME\skills\flutter-engineering-guardrails"
foreach ($dir in ".claude", ".agents", ".hermes") {
  New-Item -ItemType Directory -Force "$HOME\$dir\skills" | Out-Null
  New-Item -ItemType Junction -Path "$HOME\$dir\skills\flutter-engineering-guardrails" -Target "$HOME\skills\flutter-engineering-guardrails" | Out-Null
}
```

### Compilar las herramientas de Rust (opcional)

La skill funciona sin ellas. Los ejecutables dependen de la plataforma y no se incluyen en el repositorio: compílalos en cada equipo, desde la carpeta donde instalaste la skill.

macOS / Linux:

```bash
cd ~/.claude/skills/flutter-engineering-guardrails   # o la ruta donde la instalaste
cargo test --locked --manifest-path rust/Cargo.toml
cargo build --release --locked --manifest-path rust/Cargo.toml
./rust/target/release/flutter-rails-audit --help
```

Windows (PowerShell):

```powershell
cd "$HOME\.claude\skills\flutter-engineering-guardrails"   # o la ruta donde la instalaste
cargo test --locked --manifest-path rust\Cargo.toml
cargo build --release --locked --manifest-path rust\Cargo.toml
.\rust\target\release\flutter-rails-audit.exe --help
```

`--help` muestra el uso y termina con código 2: es lo esperado. Los ejecutables quedan en `rust/target/release/` (`.exe` en Windows). El agente los busca ahí, según `SKILL.md`.

### Actualizar y desinstalar

- **Actualizar:** `git pull` dentro de la carpeta de la skill y, si usas las herramientas, vuelve a ejecutar `cargo build --release --locked --manifest-path rust/Cargo.toml`.
- **Desinstalar:** borra la carpeta `flutter-engineering-guardrails` del directorio de skills, o el enlace si usaste una sola copia.

Las rutas de cada agente pueden cambiar entre versiones. Documentación oficial: [Claude Code](https://code.claude.com/docs/en/skills), [Codex](https://learn.chatgpt.com/docs/build-skills), [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/).

## Usar

En el agente:

- «Usa `flutter-engineering-guardrails` en modo **audit** para revisar este proyecto. No modifiques código».
- «Modo **implement**: añade la nueva pantalla respetando nuestro Provider/ViewModel».
- «Modo **refactor**: mejora esta pantalla sin cambiar su comportamiento; crea pruebas antes».
- «Modo **deep-refactor**: compara extraer features, nuevas capas o dejar como está. Quiero primero el análisis».

Si compilaste las herramientas, puedes ejecutarlas tú mismo desde la raíz de cualquier proyecto Flutter (`<skill>` es la carpeta donde instalaste la skill):

```bash
<skill>/rust/target/release/flutter-rails-audit --root .
<skill>/rust/target/release/flutter-rails-audit --root . --format json --output flutter-rails-audit.json
<skill>/rust/target/release/flutter-rails-check --root . --mode quick
```

Para mantener estas normas también en cada revisión, copia el bloque de `templates/always-on-agent-rule.md` a `AGENTS.md`, `CLAUDE.md` o la configuración equivalente. Para CI, consulta `references/quality-gates-and-ci.md`.

El escáner es **heurístico**, no sustituye `dart analyze`, tests, Flutter DevTools ni revisión humana. `flutter-rails-check` no hace `git commit`, `dart fix --apply` ni `flutter pub upgrade`.

## Perfil de proyecto

Copia `templates/project-profile.yaml` en la raíz de tu proyecto como `.flutter-rails.yaml` y adapta sus valores. Es un **contrato legible por humanos/agentes**: no implica que un CLI externo lo lea o lo aplique automáticamente. Tiene prioridad sobre las recomendaciones genéricas de esta skill, salvo errores de seguridad/corrección.

El perfil de ejemplo representa una app Flutter Web existente con Provider/ViewModel y punto de corte responsive heredado a modo ilustrativo. Cambia esos datos por los reales del proyecto.

## Filosofía

**Rails para impedir errores, no rieles para imponer estilos:** corrección, seguridad, ciclo de vida y pruebas son restricciones fuertes; arquitectura, número de capas, tipos de widgets y estructura de carpetas se deciden con evidencia.

Ver `references/sources-and-rationale.md` para la procedencia de las recomendaciones, atribuciones y límites.

## Limitaciones del port a Rust

El escáner usa patrones heurísticos, no un parser del AST de Dart. No confundir rendimiento del binario con mayor precisión de los hallazgos. Los ejecutables se compilan para cada plataforma/arquitectura (Windows, Linux, macOS) y **no se incluyen precompilados** en este repositorio (`rust/target/` está en `.gitignore`). Para que el agente invoque los comandos, primero ejecutar `cargo build --release` en su plataforma. Los checks ejecutan Flutter/Dart SDK y pueden crear cachés propios de esas herramientas; nunca aplican correcciones automáticamente.

**Validación (2026-11-13, Windows x64, Rust 1.96, Flutter 3.50 / Dart 3.14):** `cargo build --release` y `cargo test` pasan (4 tests). Ambos binarios se ejecutaron en solo lectura sobre una app Flutter desktop real (~1.200 archivos, ~200k líneas): `flutter-rails-audit` tardó 0,2 s y una revisión manual de sus señales mostró muchos falsos positivos, como corresponde a un escáner heurístico; `flutter-rails-check --mode quick` ejecutó formato y análisis correctamente. Nota: `flutter analyze` termina con error también cuando solo hay avisos *info*, y `flutter-rails-check` lo reporta como `FAIL`; revisa la salida antes de concluir que hay errores.

## Licencia

MIT. Ver [`LICENSE`](LICENSE).
