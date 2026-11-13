# Plan de refactor — [feature/archivo]

**Modo:** refactor | deep-refactor
**Cambio de comportamiento permitido:** NO (si SÍ, reclasificar como feature/migración)

## 1. Necesidad y evidencia
- Problema: [bug/duplicación/acoplamiento/ownership/UX/performance]
- Evidencia con `ruta:línea` o test/trace:
- Impacto observable:
- Objetivo mínimo medible:

## 2. Contratos que se preservan
- Entradas / salidas:
- Loading/empty/error/success:
- Rutas/back/deeplinks:
- API, serialización y persistencia:
- Responsive/design/tokens/a11y:

## 3. Alternativas
| Opción | Beneficio | Riesgo | Decisión |
|---|---|---|---|
| No modificar todavía | ... | ... | ... |
| Extraer mínimo en sitio | ... | ... | ... |
| Rediseñar feature/layer | ... | ... | ... |

## 4. Slices reversibles
| Slice | Archivos | Cambio aislado | Test previo | Criterio PASS | Rollback |
|---|---|---|---|---|---|
| 1 | ... | ... | ... | ... | ... |

## 5. Review de riesgos
- Carreras/await/dispose/listeners:
- Estado/routing/provider scope:
- Datamodel/edge cases/errores:
- Compatibilidad web/desktop:
- Dependencias nuevas (justificación):

## 6. Antes → después
- Responsabilidades removidas:
- Responsabilidades añadidas:
- Complejidad neta y clases nuevas:
- Deuda que sigue presente por decisión explícita:

## 7. Pruebas ejecutadas (solo hechos)
- [ ] Formato — comando y resultado
- [ ] Analyzer — comando y resultado
- [ ] Unit/widget tests — comandos y resultado
- [ ] Integration/manual — condiciones reales
- [ ] Métricas antes/después — medidas o «no medido»
