# Reconocimiento del repositorio antes de modificar Flutter

**Objetivo:** conseguir una fotografía concreta del código existente; el agente no debe sustituirla por sus preferencias.

## 1. Inspección mínima (lectura, sin efectos destructivos)

Desde la raíz del paquete Flutter correcto:

```bash
git status --short
git branch --show-current
find . -maxdepth 3 \( -name pubspec.yaml -o -name analysis_options.yaml \) -print
flutter --version             # si disponible
rg -n 'provider:|flutter_bloc:|riverpod:|get:|go_router:|auto_route:' pubspec.yaml
rg -n 'class .*ViewModel|extends ChangeNotifier|Consumer<|context.watch|BlocBuilder|ref.watch' lib
rg -n 'Navigator\.|Get\.(to|back|off)|GoRouter|context\.go\(' lib
find test integration_test -type f -name '*.dart' 2>/dev/null | wc -l
```

- Si hay monorepo, identifica el **paquete** de la tarea en vez de asumir que el root es una aplicación.
- Los comandos anteriores son **ejemplos**: si `rg`, `flutter` o `git` no están, recurre a herramientas equivalentes y deja constancia.
- No mezcles archivos generados (`*.g.dart`, `*.freezed.dart`), checkout, lockfile ni migraciones automáticas salvo necesidad explícita.
- No leas ni publiques archivos `.env`, secretos, claves o credenciales sin necesidad para la tarea.

## 2. Mapa mínimo de contexto

Recoge solo lo pertinente:

| Aspecto | Cuestión |
|---|---|
| SDK | Dart/Flutter admitidos por `pubspec.yaml`; capacidades realmente disponibles |
| Estado | ¿Local, compartido en feature, o de toda la app? ¿Quién lo crea y destruye? |
| UI | ¿Theme/Design System, widget reutilizable, texto, localización, responsive? |
| Red y datos | ¿Dónde se serializa/valida JSON? ¿Errores HTTP, auth, caché? |
| Navegación | ¿Un router principal, deep links, back stack, guards? |
| Tests | ¿Tests vigentes, escenarios manuales, flaky tests, coverage real? |
| Plataforma | Web, Windows/macOS/Linux, Android/iOS, tamaños relevantes |
| Release | Restricciones de plazos, compatibilidad, flags, flujos críticos |

La evidencia de código es `ruta:línea` y el comportamiento observado; **no** inventar resultados de ejecutar código no disponible.

## 3. Contratos y presupuesto de cambio

Explicita antes de actuar:

- Entradas/salidas, cargas, vacíos, errores, reintentos, pantallas y rutas afectadas.
- Comportamiento público que **no** se puede cambiar.
- Dependencias ajenas, observabilidad y límites de integración.
- Máximo alcance: hotfix, pequeño refactor, feature, migración mayor.
- Cómo revertir: un cambio aislado, toggle validado o restauración de un diff revisado.

Si la petición es pequeña, la inspección también debe ser pequeña. Un arreglo de un `TextField` no requiere leer todas las features ni generar un documento de arquitectura.

## 4. Detección de contexto progresiva

- Mirar primero los archivos exactos; después importadores y tests relevantes.
- Leer el `.flutter-rails.yaml` si existe; **no generarlo ni modificarlo por iniciativa propia**.
- Usar Graphify u otro índice solo si está instalado y mejora un problema de navegación real; no construir grafos por defecto.
- Cargar solo el módulo de referencia relevante a la tarea (ver tabla en `SKILL.md`).
- Separar hechos, hipótesis y preferencias: «usa Provider» es un hecho; «deberíamos migrar a Riverpod» es una hipótesis que requiere evaluación.
