# Modo DEEP-REFACTOR — cambios estructurales, con migración reversible

**Se activa por evidencia, no por tamaño.** El usuario puede solicitar solo el plan. No implementar de manera espontánea una migración grande.

## Umbrales cualitativos de activación

Alguno de estos argumentos, apoyado en código/tests/incidentes, debe ser fuerte:

- Un acoplamiento entre features impide pruebas, despliegues o cambios repetidamente.
- Estado/navegación con fuentes de verdad incompatibles y errores reproducibles.
- Lógica de negocio duplicada que causa divergencia funcional y alto coste de mantenimiento.
- Problema persistente de performance/memoria medido, con causa identificada.
- SDK o dependencia sin mantenimiento que exige migración por compatibilidad o seguridad.
- Un componente es prácticamente imposible de modificar con seguridad a pesar de refactors locales.

**No basta:** «el archivo tiene 700 líneas», «Clean Architecture es mejor», «queremos usar Riverpod», «todo debería ser Stateless». 

## Comparar opciones obligatoriamente

| Opción | Beneficio | Coste oculto / riesgo | Cuándo elegir |
|---|---|---|---|
| A. Mantener + hotfix/test | Cambio mínimo y entrega rápida | Puede conservar deuda | Fallo urgente, poca evidencia de rediseño |
| B. Refactor por feature en sitio | Migra gradualmente y permite rollback | Convivencia temporal de patrones | Proyecto vivo, muchas integraciones |
| C. Nuevo módulo/package delimitado | Fronteras claras, tests unitarios | API/versionado/build extra | Alta cohesión y consumidores independientes |
| D. Reescribir una pantalla/feature | Limpia núcleo aislado | Riesgo de casos desconocidos | Componente acotado con tests/contratos |
| E. Reescritura completa | Arquitectura coherente a largo plazo | Máxima regresión, costes y plazo | Solo con alcance, tests y beneficios superiores demostrados |

Nunca proponer «E» sin inventario funcional/contractual, tamaño real, integraciones, coste de mantener dos apps y aceptación explícita del responsable.

## Migración por strangler / slices

1. Cartografiar dominios, rutas, funcionalidades y dependencias.
2. Seleccionar feature piloto no crítica pero representativa.
3. Congelar contratos (schema, estado, deep link, analytics, errores, UX, auth).
4. Crear pruebas de caracterización y test contractuales; identificar incompatibilidades.
5. Añadir frontera/adaptador **solo** si permite coexistencia realmente necesaria.
6. Migrar feature piloto y demostrar paridad; supervisar crashes, timings, UI y support.
7. Expandir feature por feature con retirada **programada** de código legado.
8. Eliminar wrappers temporales y flags cuando verificados; documentar rollback.

## Entregables de diseño

- ADR ligero: problema, alternativas, decisión y condición de revocación.
- Diagrama simple de dependencias actuales/objetivo (no diagrama decorativo gigante).
- Tabla «contrato → test de equivalencia → responsable».
- Plan por milestones: scope, criterios de aceptación, riesgos, reversión.
- Métricas **reales** (jank, memory, incidencias, duración builds, tests), si existen. Si no existen, diseñar medición antes de optimizar.
- Política de no mezclar cambios: nuevos patrones no se expanden a todas las features sin justificación.

## Paquetes y carpetas: adaptación, no obligación

La analogía con `Adaptive Crate Architecture` de Rust es una **arquitectura adaptativa de features/packages**. Extraer a package requiere beneficio neto de aislamiento, contrato, consumo compartido o ownership. Si una simple carpeta resuelve bien el problema, conservar carpeta.

## Criterios de salida / rollback

- Una feature migrada pasa contract tests de éxito/error/estado/vuelta/responsive según corresponda.
- No hay incremento inexplicado de crashes/regresiones.
- La solución sigue siendo testeable, documentada y reversible.
- Si falla una puerta de calidad, detener expansión y corregir/volver, no continuar por inercia.
