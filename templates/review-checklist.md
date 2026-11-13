# Flutter PR / código generado por agente — checklist de revisión

> Marcar SÍ / NO / N/A con evidencia; no marcar automáticamente.

## Exactitud
- [ ] Aceptación y casos límite definidos
- [ ] Rutas loading/empty/error/success según el flujo
- [ ] Sin null assertions/casts sin precondición
- [ ] Contratos API/autorización preservados

## Async, estado y recursos
- [ ] Los propietarios de controllers/stream/timers están claros
- [ ] `dispose()`/removeListener/cancel donde corresponde
- [ ] No UI update sobre widget desechado
- [ ] Sin respuestas obsoletas ni doble-submit involuntario
- [ ] Estado único/coherente, no lógica negocio duplicada en UI

## Diseño, plataforma y rendimiento
- [ ] Breakpoints/Theme existentes respetados
- [ ] Zoom/text scaling/teclado/semántica adecuados
- [ ] Sin I/O costoso en `build()` ni builders eager gigantes
- [ ] Sin afirmaciones de mejora sin medidas

## Arquitectura
- [ ] Patrón state/routing actual respetado o migración justificada
- [ ] Cada nueva abstracción resuelve un problema concreto
- [ ] No dependency churn/no codegen irrelevante
- [ ] Separación packages/feature solo con beneficio neto

## Verificación
- [ ] Formatter/analyzer efectivamente ejecutados (si disponibles)
- [ ] Tests unit/widget relevantes y regresiones
- [ ] Fallos preexistentes distinguidos de nuevos
- [ ] Cambios pequeños, revisión y rollback factibles
- [ ] Informe explícito de no comprobado, sin «todo OK» inventado
