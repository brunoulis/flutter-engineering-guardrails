# Revisión adversarial de código Flutter y evaluación con evidencia

## La revisión no debe limitarse a encontrar lint warnings

El revisor actúa como mantenedor: busca *errores reales y coste futuro*, no si la IA siguió un estilo arbitrario. Si existen varias soluciones válidas, debe explicar trade-offs en vez de declarar «incorrecta» la alternativa.

### Cinco pasadas

1. **Correctitud:** contrato, casos límite, null-safety, parse, permisos, `Result`, estados posibles e invariantes.
2. **Ciclo y concurrencia:** ownership/dispose, `await`, respuesta obsoleta, doble tap, navegación async, recursión y streams.
3. **Arquitectura:** separación donde aporta valor, dependencias, duplicación significativa, single source of truth, «abstracción innecesaria».
4. **Experiencia y rendimiento:** loading/error/empty, responsive, a11y, list builders, trabajo en build, jank medible.
5. **Pruebas y entrega:** regresiones, tests del límite, analyzer, alcance de diff, rollback y documentación de decisiones.

### Hallazgos con prioridad

Ordena por **P0 a P3** (definición en `refactor-audit.md`). Para cada hallazgo incluye ubicación, escenario, impacto, cambio mínimo y prueba que demostraría su corrección. No llenar un review con asuntos cosméticos si hay un error grave.

## Calidad multidimensional (opcional, no es un número mágico)

| Dimensión | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Correctitud/errores | Bugs reproducidos sin tratar | Rutas críticas sin manejo | Contrato mayormente cubierto | Contratos y edge cases verificados |
| Async y lifecycle | Fugas/carreras demostradas | Ownership ambiguo | Cleanup razonable | Cleanup y races comprobados |
| Claridad/modularidad | Flujo inabordable | Dependencias confusas | Responsabilidades legibles | Complejidad neta baja y límites claros |
| Pruebas | Ausentes en rutas críticas | Solo happy path | Casos importantes cubiertos | Regresiones y negativos comprobados |
| UI/a11y/responsive | Flujos bloqueados | Fragilidades visibles | Usable en targets | Comprobación de edge cases |
| Performance | Problema medido grave | Sospecha sin medir | Sin problema conocido | Medición adecuada y regresión controlada |

**Reglas de puntuación:** solo asignar 0–3 con evidencia concreta por dimensión; si no hay datos escribir `N/E (no evaluado)`. No sumar a «89/100», no confundir impresión con dato ni comparar repos por esta tabla.

## Preguntas obligatorias antes de aprobar un refactor

- ¿La app hace lo mismo antes y después según pruebas/caracterización?
- ¿Se ha reducido complejidad o se ha desplazado a más archivos?
- ¿Los nuevos límites tienen responsabilidad única demostrable?
- ¿La elección de estado/navegación es coherente con el proyecto?
- ¿El usuario podrá mantener esto sin pedir a una IA que reconstruya el contexto de 15 capas?
- ¿Hay algo que se podría **no** refactorizar por ahora?

## Comentario de code review útil

**Malo:** «Usa Clean Architecture, divide en 6 capas». 

**Bueno:** «En `lib/features/search/search_vm.dart:88`, la llamada A puede terminar después de B y sobrescribir resultados. Reproducción con dos completers; propongo comprobar ID de solicitud antes de publicar estado, sin cambiar Provider». 

Utiliza [`../templates/review-checklist.md`](../templates/review-checklist.md) como checklist final cuando el cambio sea grande.
