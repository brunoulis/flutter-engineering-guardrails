# Instrucción mínima de proyecto para AGENTS.md, CLAUDE.md o Hermes

Inserta el texto siguiente en **la configuración propia del agente/proyecto** si quieres que las reglas sean persistentes sin repetir el prompt en cada tarea. No es obligatorio.

---

Para cualquier cambio o revisión de Flutter/Dart, usa la skill `flutter-engineering-guardrails`. Carga solo sus referencias relevantes a la tarea. La fuente de verdad es el código, las convenciones del proyecto y el archivo `.flutter-rails.yaml` (si existe). En ausencia de evidencia, no introduzcas arquitectura, estado, librerías ni paquetes nuevos. Prioriza corrección, propiedad y liberación de recursos, tests de regresión, UI responsive/accesible y cambios pequeños reversibles. Usa `audit` para diagnóstico sin modificaciones; `implement` para features; `refactor` para limpieza con comportamiento preservado; `deep-refactor` para migraciones justificadas. No afirmes que se han ejecutado pruebas o mejorado el rendimiento si no existe evidencia.

---

**Aviso:** esto no equivale a CI ni hooks. Si el agente no tiene instalada/disponible la skill, debe declarar la limitación en vez de fingir que la aplicó.
