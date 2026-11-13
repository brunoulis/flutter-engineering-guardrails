# Origen de las reglas y límites de interpretación

## Los tres debates de FlutterDev

1. **AI is reducing my productivity** — https://www.reddit.com/r/FlutterDev/comments/1s9csar/ai_is_reducing_my_productivity/
   - Opiniones enfrentadas sobre delegar programación frente a mantener criterio técnico.
   - Señales: código generado que parece correcto pero tiene atajos, casos límite sin cubrir, abstracciones pobres y revisión costosa.
   - Extracción: diseñar antes de implementar, exigir revisión humana de contratos, riesgos y pruebas; no hacer que un agente reemplace la comprensión del desarrollador.
   - **No implica** que toda IA empeore la productividad; los comentarios son experiencias personales, no benchmarks controlados.
2. **Flutter skills to make your AI agents smarter** — https://www.reddit.com/r/FlutterDev/comments/1raz7ry/flutter_skills_to_make_your_ai_agents_smarter/
   - Enlace principal compartido: https://playbooks.com/for/flutter. Su utilidad se plantea como contexto especializado para agentes; no debe tratarse como autoridad superior al SDK/documentación.
   - Extracción: skills modulares cargadas bajo demanda; fuentes de contexto verificables, no alucinación de APIs; uso de herramientas oficiales.
3. **Refactoring Extremely Bad Flutter Code** — https://www.reddit.com/r/FlutterDev/comments/18gz1o9/refactoring_extremely_bad_flutter_code/
   - Problemas descritos: estado mal gestionado, GetX/Navigator mezclados, controladores sin dispose, errores no tratados, `Map` sin tipar, lógica en widgets, pocos tests.
   - Consejos repetidos: no reescribir sin comparar costes; delimitar fallos, formatter/lints, pequeños cambios/commits, pruebas de regresión, refactorizar por feature, documentar decisiones y negociar alcance.
   - Hay opiniones contrarias sobre reescribir; no tomar el voto de un comentario como prueba universal. Nuestra regla es **decisión condicionada**, no prohibición absoluta.

## Material técnico prioritario

- Estándar Agent Skills (frontmatter y estructura): https://agentskills.io/specification
- Flutter Agent Plugins oficiales: https://github.com/flutter/agent-plugins
- Dart Skills oficiales: https://github.com/dart-lang/skills
- Flutter + Dart MCP y skills: https://docs.flutter.dev/ai/get-started y https://docs.flutter.dev/ai/tools
- Arquitectura recomendada adaptable: https://docs.flutter.dev/app-architecture/guide
- Tests de unidad/widget/integración: https://docs.flutter.dev/testing/overview
- Performance: https://docs.flutter.dev/perf/best-practices
- Manejo de errores: https://docs.flutter.dev/testing/errors y https://docs.flutter.dev/app-architecture/design-patterns/result
- `dart fix --dry-run` y aplicación explícita: https://dart.dev/tools/dart-fix
- `dart analyze`: https://dart.dev/tools/dart-analyze
- Accesibilidad: https://docs.flutter.dev/ui/accessibility

## Principios de atribución

- Las reglas son una **síntesis original**; no copiar hilos ni colecciones de terceros palabra por palabra.
- Priorizar reglas actuales del SDK/paquete existente frente a recomendaciones históricas (el hilo de refactor data de años anteriores).
- Nada de afirmaciones falsas de benchmark, bugs «confirmados» por un regex, código sin verificar o «sin bugs garantizado».
- Tener `flutter analyze` verde no demuestra ausencia de defectos de interfaz, datos, concurrencia o UX.
