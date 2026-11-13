# Rails automáticos vs revisión: quality gates proporcionales

**Importante:** `SKILL.md` da instrucciones al agente; no ejecuta automáticamente controles. Para convertir esas políticas en **enforcement**, el proyecto debe integrar CI/hook/scripts con autoridad explícita. Nunca afirmar que la skill «garantiza» la calidad del código.

## Nivel 1 — Feedback rápido (durante la tarea)

- Consultar diagnósticos concretos del IDE / Dart MCP si existen.
- Analizar el archivo o feature afectada y probar la lógica relevante.
- Ejecutar `dart fix --dry-run` solo cuando hay lints/fixes que revisar.
- Evitar format/lint de todo el repo en hotfix que produciría miles de líneas de ruido.

## Nivel 2 — Pull request (definir en CI del repositorio)

Ejemplo de comandos **a adaptar**:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

La opción `--no-pub` presupone dependencias ya obtenidas; el pipeline puede incorporar una fase separada de `flutter pub get` con caché/lockfile bajo sus propias políticas.

- Un PR debería bloquearse por fallos de formato, análisis estricto configurado y tests relevantes cuando el entorno lo permite.
- La auditoría heurística es **informativa**, no gate automático de bloqueo (falsos positivos).
- No publicar métricas «0 warnings» si no se midió el conjunto correspondiente.

## Nivel 3 — Cambios críticos / release

- Tests contractuales de autenticación, permisos, persistencia, flujos críticos y errores.
- Widget/integración para rutas y escenarios de teclado, web/desktop o móvil según targets.
- Observabilidad y DevTools cuando hay cambios de rendimiento o memory.
- Plan/feature flag/rollback para migraciones amplias.

## Baseline en proyectos heredados

1. Medir warnings/errores **existentes** sin modificarlos.
2. Bloquear introducción de **nuevos** errores en áreas tocadas mientras se reduce gradualmente el baseline existente.
3. Escoger lints prioritarios por corrección y mantenibilidad, no maximizar recuento de reglas.
4. Usar lints nuevos mediante PR separado con justificación y auto-fix previsualizado.
5. No excluir todo el código viejo sin dejar ownership ni fecha de revisión.

## Plantilla de política de revisión

```text
Para cambios Dart/Flutter:
- El agente debe aplicar flutter-engineering-guardrails.
- Prohibido cambiar state-management, routing, paquetes o contratos en un refactor local sin justificación.
- Las modificaciones grandes requieren characterization tests y plan de slices.
- Antes de aprobar, CI debe ejecutar format/analyze/test según el tipo de cambio.
- No se aceptan claims de rendimiento sin medición ni tests inventados.
```
