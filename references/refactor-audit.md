# Modo AUDIT — diagnóstico sin tocar el código

## Contrato

**PROHIBIDO editar, formatear o ejecutar auto-fixes.** Puedes leer, ejecutar herramientas de análisis no mutadoras y proponer un plan. Diferencia hallazgo demostrado de un riesgo por inspección.

### Inventario inicial

- Alcance: paquete(s), features, tests, `analysis_options.yaml`, Estado/routing/serialización, deuda conocida.
- Baseline: `git status`, `dart analyze`/`flutter analyze` si posible; pruebas existentes; ramas/flujos que no se deben tocar.
- Detalles del entorno: versiones reales SDK, plataformas, paquetes relevantes, comandos existentes de CI.
- Dependencias importadas y **código generado**; no reportar código autogenerado como refactor manual.
- Señales de riesgo: incidencias recurrentes, cambios difíciles, errores de producción, tests flakey, fugas o jank medidos.

### Catálogo de observaciones (evidencia antes que opinión)

| Categoría | Buscar | Interpretar cuidadosamente |
|---|---|---|
| Corrección | errores no tratados, `!` inseguro, `Map` con casts, reglas dispersas | Necesita contrato y caso concreto |
| Async y lifecycle | `await`→context/notify, controllers sin dispose, listeners/timers | Revisar **propietario real** y orden de eventos |
| Estado | doble fuente de verdad, notify masivo, mutaciones no notificadas | El framework de estado no es el problema por defecto |
| Routing | `GetX` y `Navigator`/go_router mezclados, historial incoherente | Verificar que la mezcla realmente rompe flujos |
| Separación | `build()` hace I/O, lógica negocio dispersa, UI acoplada al HTTP | Extraer solo si mejora comprensión/test |
| Datos | serialización JSON en widgets, strings mágicos de backend | Tipar frontera; no tipar ciegamente todo |
| Tests | lógica crítica sin pruebas, tests acoplados a detalles internos | Empezar por comportamiento observable |
| Rendimiento | lists eager gigantes, trabajo pesado en build, jank medido | Medir y comparar antes de afirmar causa |
| Accesibilidad | iconos sin semántica, foco y teclado, escalado texto | Probar la interacción real |
| Higiene | `ignore_for_file`, código muerto, lints/format | Priorización baja salvo efecto funcional |

### Severidad y confianza

- **P0 / crítico:** seguridad, pérdida/corrupción de datos, crash reproducible grave. Requiere evidencia concreta.
- **P1 / alto:** error funcional probable, carrera real, memory leak con impacto, bloqueo de release.
- **P2 / medio:** mantenimiento, testabilidad, duplicación real, fragilidad.
- **P3 / bajo:** cosmética, nombres o microduplicaciones sin impacto.

Evidencia de cada hallazgo:

```text
ID: FL-007
Nivel: P1 | Confianza: probable
Archivo: lib/features/orders/order_view_model.dart:123
Señal: una respuesta tardía puede sobrescribir una búsqueda posterior.
Consecuencia: datos de otra búsqueda mostrados.
Prueba: test A→B con Future controlados, B completa antes que A.
Solución mínima: descarte de generación obsoleta dentro del ViewModel existente.
Riesgo del cambio: bajo / controla solo ese flujo.
```

**Confianza:** `confirmado` = test, stack trace, reproducción o diagnóstico inequívoco; `probable` = razonamiento específico sobre el flujo real; `heurístico` = búsqueda estática sin confirmar. **Nunca marcar «fuga confirmada» a partir del nombre de un controller.**

### Escáner local

```bash
/ruta/skill/rust/target/release/flutter-rails-audit --root . --format text
/ruta/skill/rust/target/release/flutter-rails-audit --root . --format json --output audit.json
```

- Implementación estática con regex deliberadamente conservadora; **no hace parsing de Dart AST** ni detecta todos los casos.
- No sustituye `flutter analyze`, instrumentación, tests ni inspección de ownership.
- No asignar porcentajes «de calidad» a partir de número de findings.

### Priorización y plan

Clasifica cada ítem por impacto real, coste, riesgo de regresión y cobertura existente. Ofrece **máximo tres slices iniciales**, dejando backlog con dependencias para el resto. No usar «reescribir todo» como diagnóstico automático.

Usa la plantilla [`../templates/audit-report.md`](../templates/audit-report.md).
