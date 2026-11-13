# Estrategia de pruebas y validación por riesgo

Guía oficial: https://docs.flutter.dev/testing/overview. Flutter distingue tests unitarios, de widgets e integración; combinar según el coste y la criticidad. Nunca declarar cobertura no medida.

## Gate progresivo

| Cambio | Comprobación mínima sugerida | Ampliar cuando... |
|---|---|---|
| Texto/estilo pequeño | `dart format`/analyzer parcial + inspección visual | Responsive/a11y o layout frágil |
| Función pura | Unit tests + analyze | Tiene decisiones de negocio |
| Formulario/ViewModel | Unit tests de estado y error + widget test de interacción | Valida, navega, persiste o usa varias requests |
| Controlador/stream/listener | Lifecycle test: crear, usar, desmontar, volver | Hay timers, cancelaciones, race conditions |
| Routing/deep links | Widget/integration test de entrada/back/params | Web/history/auth guard |
| Servicio/API | Contract/parse tests para éxito/error/malformed | Tiene retry, paginación, caché o auth |
| Refactor de feature | Characterization/regression antes/después | Cambia múltiples componentes |
| Migración de arquitectura | Contract parity + integration/regression + rollback | Cambia persistencia, sesión, auth, navegador |
| Rendimiento | Profiling comparable antes/después | El problema depende de dispositivo y escala |

## Comandos de ejemplo — siempre ajustar al repo

```bash
# Lectura / sin mutación de fuente
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/features/orders/order_view_model_test.dart
flutter test # si el alcance lo justifica y los tests existen

dart fix --dry-run # ver cambios automáticos propuestos; NO aplica
```

Al usar subdirectorios con `dart format`, pasar solo los que existen. `flutter test` y `flutter analyze` requieren SDK/dependencias adecuados; informar si no están disponibles. Las herramientas pueden crear artefactos temporales de build aunque no cambien fuentes.

## Pruebas de caracterización para refactors

1. Registrar el comportamiento **real**, incluidos los comportamientos raros que sean contratos vigentes (si son bugs, separarlos).
2. Generar inputs representativos y edge cases: vacío, nulo, inválido, duplicado, reintento, red lenta, orden inverso, cancelación/desmontaje.
3. Usar fakes deterministas, no requests reales ni sleeps arbitrarios donde se puede controlar Futures/streams.
4. Verificar outputs y efectos visibles, no nombres de métodos privados ni estructura de widgets internos sin necesidad.
5. Solo después cambiar diseño, manteniendo tests verdes; actualizar tests únicamente por cambios de contrato aprobados.

## No esconder regresiones

- No introducir `skip`, supresión masiva de lints o mocks que eliminen el comportamiento bajo prueba.
- Diferenciar **fallo preexistente**, **nuevo fallo**, **test no ejecutado**, **test no disponible**.
- Cuando un golden falla, inspeccionar el render real y la causa, no regenerarlo ciegamente.
- Analizar flaky tests por sincronización, reloj, animaciones, mock dependencies y async pending.
- En CI, separar checks obligatorios del informe heurístico (que puede tener falsos positivos).

## Reporte de verificación honesto

```text
Formato: PASS — dart format --output=none --set-exit-if-changed lib test
Analyzer: PASS — flutter analyze
Tests: PASS — flutter test test/features/order_flow_test.dart
Integración: NOT RUN — requiere navegador/credenciales de test
Riesgo residual: historial/back de ruta /orders no comprobado manualmente
```

Solo imprimir `PASS` si el agente ejecutó el comando y comprobó exit code 0.
