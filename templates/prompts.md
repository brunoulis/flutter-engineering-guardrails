# Prompts listos para Claude Code, Codex o Hermes Agent

## 1 — Audit de un proyecto Flutter legado

Usa la skill `flutter-engineering-guardrails` en modo `audit`. Inspecciona el repositorio real y detecta su arquitectura, versión Flutter/Dart, state management, router, tests y convenciones. NO modifiques archivos ni hagas auto-fixes. Audita lifecycle/async, ownership de controllers, lógica de negocio dentro de UI, rutas, JSON no tipado, errores silenciosos, duplicación y performance en puntos críticos. Separa hallazgos **confirmados/probables/heurísticos**, siempre con archivo:línea, caso de fallo, solución mínima y prueba. Prioriza P0–P3. Entrega tres slices incrementales de máximo valor y qué NO tocar todavía. Evita proponer un framework nuevo sin evidencia.

## 2 — Implementar una feature Flutter con calidad

Usa `flutter-engineering-guardrails` en modo `implement`. Primero identifica la estructura y los patrones existentes, incluyendo `.flutter-rails.yaml` si está presente. Define contrato y estados UI, propietario de los datos, caminos de error/loading/empty, navegación, plataformas y responsive. Implementa el menor cambio bien estructurado. Respeta Provider/ViewModel (o el framework real), no añadas capas genéricas sin necesidad, protege `await` y dispose, y crea unit/widget tests apropiados. Ejecuta formatter, analyzer y tests disponibles, reportando resultados reales y límites.

## 3 — Refactor de una pantalla que funciona pero es difícil de mantener

Usa `flutter-engineering-guardrails` en modo `refactor`. No cambies comportamiento, contratos ni el diseño visual. Localiza responsabilidades mezcladas, dependencias y ownership. Crea un test de caracterización antes de editar, salvo que exista una prueba suficiente. Compara no hacer nada, extracción pequeña y nueva capa, elige el cambio mínimo eficaz. Mueve lógica fuera de `build()` cuando tenga valor, corrige async/lifecycle y estados inconsistentes, pero evita reescribir rutas/estado de todo el proyecto. Un objetivo estructural por slice, con tests después, comparación antes/después y rollback.

## 4 — Deep-refactor justificado, sin reescritura automática

Usa `flutter-engineering-guardrails` en modo `deep-refactor` y **por ahora solo planifica**. Audita la feature o app para identificar causas comprobables de deuda técnica. Compara hotfix, refactor incremental, feature/package y reescritura parcial/completa. Calcula riesgos cualitativos, contratos que se deben preservar, tests de equivalencia y plan de migración por slices con adaptadores temporales y rollback. No impongas Riverpod/BLoC/Clean Architecture, no muevas todo a packages y no prometas mejoras de CPU/RAM sin mediciones.

## 5 — Revisión adversarial del código generado por IA

Usa `flutter-engineering-guardrails` como revisor que NO cambia código. Busca problemas de comportamiento aunque `flutter analyze` pase: entradas raras, JSON inválido, conexión fallida, carreras A→B, doble tap, context tras await, controllers/suscripciones sin cleanup, callbacks que esconden errores, UI acoplada, overengineering y pruebas que solo validan happy path. Reporta únicamente hallazgos relevantes con ruta:línea y prueba propuesta; indica qué aspectos están bien fundamentados. Evita feedback cosmético y números inventados.
