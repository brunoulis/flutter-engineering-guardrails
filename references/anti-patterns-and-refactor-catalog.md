# Catálogo de code smells Flutter: detector → decisión → refactor mínimo

**Nota:** Un smell **no es automáticamente un bug**. Hay que comprobar contexto, alcance, causa y pruebas antes de intervenir.

| Smell | Síntoma útil | Refactor mínimo | Verificación / cuándo dejarlo |
|---|---|---|---|
| God widget | UI + I/O + validación + mutaciones + rutas en un archivo | Extraer reglas puras o VM existente por responsabilidad | Widget test y contratos de navegación; si el archivo es largo pero cohesivo, no fragmentar |
| `FutureBuilder` que recrea future | Requests repetidos durante rebuild | Retener future en lifecycle o trasladar al VM | Contar requests tras `pump`/rebuild |
| `setState()` global innecesario | Animación/filtro local invalida toda la vista | Mover estado a subárbol propietario | DevTools antes/después, no asumir jank |
| `ChangeNotifier` gigante | Un notifier contiene estado de features inconexas | Separar solo estados con ownership distinto | Tests de listeners/disposal; evitar acoplamientos cíclicos |
| `notifyListeners()` tras dispose | Error en respuesta tardía | Cancelar/descartar futuro; ownership claro | Abrir/cerrar pantalla antes de completar request |
| Doble fuente de verdad | Controller y VM guardan valor mutable divergente | Elegir fuente y definir sincronización | Form submit/reset/validation y navegación |
| Constructor 15 parámetros | Objeto maneja responsabilidades dispares | Agrupar datos cohesivos o dividir responsabilidad si justificado | API pública y tests; no crear DTO wrapper vacío |
| `Map<String,dynamic>` por todo widget | Claves/backend invaden UI | Parsear una vez al entrar en capa de datos | Payload incorrecto, campos opcionales y casos esperados |
| `!` por doquier | El código oculta precondiciones | Asegurar invariante/case explícito | Test de datos nulos/incompletos; `!` puede estar justificado |
| `catch (_) {}` | Fallo silencioso y UX rota | Estado error + reporte seguro/reintento | Simular fallo y verificar respuesta UX |
| Listener/controller olvidado | Cierre de pantalla deja observadores vivos | `dispose`/`removeListener` de propietario | Leak test/múltiples montajes |
| Build con llamadas de red | Llamada repetida en cada reconstrucción | Mover side effect a lifecycle/VM con contrato | Verificar requests y estados |
| Navigation API mezclada | Back-stack inconsistente | Unificar gradualmente rutas afectadas | Deep links, back/forward, login guards |
| Repositorio por endpoint | Abstracción duplicada y ceremonial | Consolidar cuando sea coherente | Cambios de dependencias no rompen tests |
| `BaseWidget/BaseUseCase` universales | Herencia oculta estado/efectos | Composición/concreción según necesidad | Menor navegación entre archivos sin perder reuse |
| Duplicación en 2 lugares | Tentación de framework prematuro | Esperar si divergen semánticamente, extraer si cambian juntos | Test de regla compartida; no DRY a cualquier precio |
| Variables/estilos mágicos | Inconsistencia visual real | Usar theme/tokens existentes | Screenshot/golden o revisión UI; no extraer cada número aislado |
| Listas enormes eager | Lag/memoria con miles de elementos | Builders perezosos y paginación | Dataset representativo y profiling |
| `context.mounted` ausente | Context usado tras await | Guard con contexto correcto + control de solicitudes | Test async y desmontaje; mounted no evita stale results |
| Mock de todo | Tests frágiles a diseño interno | Fakes contractuales y pruebas de efectos | Refactor inocuo no debería romper tests |

## Patrones de transformación

### Extract pure rule

Usar si hay regla de negocio que debe probarse separada de Flutter. Evitar abstraer solo porque el bloque tiene más de N líneas.

### Extract widget

Usar cuando hay responsabilidad visual independiente, límites de props comprensibles o rebuild local significativo. No convertir cada `Padding` en clase.

### Introduce typed boundary

En el servicio/DTO al recibir JSON: validar estructura de forma explícita y dejar errores visibles a la capa encargada. Migrar **endpoint a endpoint**, no `Map` entero de toda la app en una PR.

### Replace temporary conditional with semantics

Una cascada de ternarios para empty/loading/error puede transformarse en un estado explícito o métodos cortos. No forzar `sealed` si SDK o estilo no acompañan.

### Consolidate routing

Conservar la API pública de rutas mientras se migra por feature, con adapter si es indispensable y fecha de retiro. Un `Navigator.pop` aislado no exige reescribir todo el router.

### Remove unnecessary abstraction

Detectar clases sin estado ni contrato que solo delegan a otra función. **No eliminarlas automáticamente:** pueden ofrecer estabilidad de API, sustitución en tests o ownership real.

## Detener el refactor si...

- No hay forma de reproducir o caracterizar comportamiento crítico.
- El cambio crece de pantalla a navegación/backend entero sin justificarlo.
- Los tests pasan porque se han desactivado o se han debilitado las aserciones.
- El agente no puede explicar qué responsabilidad desaparece y cuál se añade.
- La mejora es únicamente un menor número de líneas o una mayor «pureza» arquitectónica.
