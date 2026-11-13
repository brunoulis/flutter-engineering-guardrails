# Modo REFACTOR — transformación segura por cortes verticales

## Definición

Un refactor **preserva comportamiento observable**. Si se cambia UX, API, persistencia, navegación, permisos, estructura de respuesta o efecto de negocio, eso es **cambio funcional o migración**, y debe etiquetarse como tal.

## El protocolo de 9 pasos

1. **Delimitar:** función/widget/feature y contrato exacto; identificar restricciones y archivos prohibidos.
2. **Caracterizar:** capturar tests existentes, golden/escenarios manuales y errores conocidos. Un test fallando de antemano se informa, no se atribuye al refactor.
3. **Dependencias y ownership:** dibujar flujo `UI → ViewModel → repository/service → API`; localizar rutas, sesiones, timers, listeners, modelos.
4. **Elegir una sola intención:** extracción de lógica, tipado de una respuesta, división de widget, lifecycle o migración de una ruta. No combinar intenciones sin necesidad.
5. **Cambio pequeño:** conservar API; opcionalmente introducir adaptador; separar formateo mecánico en diff propio.
6. **Verificación local:** formatter/analyzer + test afectado y dos rutas de fallo; añadir regression tests de bugs detectados.
7. **Revisión adversarial:** ¿qué puede romper si cambia la red, la pantalla se destruye, hay dos solicitudes o falla parsing?
8. **Comparación:** responsabilidades/differences antes/después, deuda eliminada, deuda diferida, coste de nuevas abstracciones.
9. **Rollback:** diff sencillo o restauración manual, feature flag si es cruce de sistemas; no `git commit` sin permiso.

## Cinco refactors de mayor valor

**A. UI ↔ lógica:** extraer una regla que necesita pruebas fuera de `build()` al ViewModel/función pura existente. Mantener callbacks/controlador; no introducir capas extra sin razón.

**B. Tipado gradual en fronteras:** convertir una respuesta de API por vez de `Map<String, dynamic>` a modelo con validación. Añadir tests de payload ausente, nulo, tipo inesperado y éxito. No cambiar toda la red a la vez.

**C. Stateful y lifecycle:** identificar propiedad de controllers/streams/listeners, cerrar en dispose, manejar `didUpdateWidget` y respuestas fuera de orden. Test destruir/volver a crear.

**D. Widgets grandes:** extraer componentes por cohesión UI, entradas claras y áreas de rebuild; no «un widget por línea». Comparar visibilidad/constraints antes y después.

**E. Routing:** centralizar gradualmente la navegación en el stack establecido. Probar entrar, volver, deeplink, pantalla anidada e historial web antes de retirar API vieja.

## Orden recomendado para legado complicado

1. Registrar baseline de warnings y fallos.
2. Separar cambios puramente mecánicos (formato/lints) **solo si el diff resultante es revisable**. Previsualizar `dart fix --dry-run`; limitar `--apply` a reglas/áreas acordadas.
3. Corregir fallos concretos y crear tests de regresión.
4. Extraer lógica/estado en features que realmente se editan.
5. Mejorar integración y repetir. Reescribir pantallas individuales dentro de la app puede ser válido si disminuye riesgo y coste global.

Nunca ocultar errores de CI con `// ignore_for_file` generalizado, `dynamic`, `try/catch` vacío o `skip:` masivo. Excepciones puntuales necesitan motivo y ticket/fecha de revisión.

## Ejemplo: un refactor útil pero pequeño

Antes (dentro del callback UI):

```dart
onPressed: () {
  final total = products.fold<double>(0, (sum, p) => sum + p.price);
  if (total > 100) {
    showDiscount();
  }
}
```

Después, si la regla de descuentos es negocio que se repite y necesita pruebas:

```dart
bool qualifiesForDiscount(Iterable<Product> products) {
  final total = products.fold<double>(0, (sum, p) => sum + p.price);
  return total > 100;
}
```

La UI sigue ejecutando `showDiscount()` solo si la función devuelve true. Probar límite 100, 100.01, iterable vacío y productos relevantes. **Si la regla es única y trivial, también puede ser mejor dejarla donde está.**

Usa la plantilla [`../templates/refactor-plan.md`](../templates/refactor-plan.md).
