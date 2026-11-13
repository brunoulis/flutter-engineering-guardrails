# Async, ownership, lifecycle y gestión de fallos

## Inventario de recursos (obligatorio cuando se toca una pantalla con estado)

| Recurso | Propietario típico | Liberación / condición |
|---|---|---|
| `TextEditingController`, `FocusNode` | Estado del formulario, salvo inyección | `dispose()` si la instancia es propia |
| `AnimationController`, `TabController` | `State` o objeto propietario | `dispose()`; revisar `TickerProvider` |
| `ScrollController`, `PageController` | Vista que los crea | `dispose()` y callbacks al cambiar widget |
| `StreamSubscription` | Servicio/notifier/State que se suscribe | `cancel()` y plan para errores de stream |
| `Timer` (incl. periodic) | Componente que lo crea | `cancel()` antes de liberar dependencias |
| Listeners en `ChangeNotifier` | Objeto que hace `addListener` | `removeListener()` cuando deja de observar |
| Future HTTP | Caso de uso/estado dueño de la petición | Cancelación si cliente lo permite; impedir efectos tardíos si no |
| `ChangeNotifier` / Provider | Constructor o scope de Provider | `dispose()` por el **creador**, no por cada consumidor |
| Isolate/event channel/IPC | Servicio que inicia el canal | shutdown ordenado y manejo de desconexión |

Importante: **no** hacer `dispose()` de un controlador recibido desde fuera si pertenece a otro objeto. Si cambia una dependencia que escucha el widget, revisar `didUpdateWidget` y limpiar/reasignar listeners.

## Async: cinco fallos comunes

1. **`setState` o uso de `BuildContext` tras `await`** sin comprobar si el widget sigue montado.
2. **Respuestas fuera de orden**: la solicitud A empieza, luego B; B termina primero, pero A pisa su estado.
3. **Doble envío** de formularios o navegación duplicada durante carga.
4. **`FutureBuilder(future: fetch())`** creado durante rebuild, provocando peticiones repetidas.
5. **Excepciones descartadas** con `catch (_) {}`, `print` y continuación en estado inválido.

`context.mounted` protege un contexto tras el `await`, pero **no evita respuestas obsoletas** ni cancela una petición; son problemas diferentes.

## Ejemplo ilustrativo: ViewModel con resultados obsoletos

```dart
class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._repository);
  final SearchRepository _repository;

  int _generation = 0;
  bool _disposed = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<SearchItem> _items = const [];
  List<SearchItem> get items => _items;
  Object? _lastError;
  Object? get lastError => _lastError;

  Future<void> search(String query) async {
    final generation = ++_generation;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _repository.search(query);
      if (!_isCurrent(generation)) return;
      _items = List<SearchItem>.unmodifiable(result);
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _lastError = error; // Adaptar: mapear a un error seguro para la UI.
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
```

Es **un patrón posible**, no una obligación. En este ejemplo se conservan resultados previos durante carga/error; decidirlo explícitamente según UX. La propia librería de estado/petición puede gestionar cancelación y ordering. Tipos `SearchRepository` y `SearchItem` son interfaces del ejemplo, no librerías reales.

## Manejo de errores con sentido

- Distinguir fallos **esperables** (sin conexión, 401, timeout, 404 de recurso) de fallos **inesperados** (contrato JSON inválido, bug, estado imposible).
- Un error recuperable debe convertirse en estado UX útil con reintento seguro si corresponde. **No** devolver datos silenciosamente incorrectos como si hubiera éxito.
- Logs con contexto técnico suficiente para diagnóstico, sin tokens, datos de personas o cuerpos completos confidenciales.
- No repetir/reintentar operaciones no idempotentes de forma automática sin protección frente a duplicados.
- El patrón `Result<T>` es opcional, recomendable cuando consumidores deben actuar según clases de fallo; no introducirlo de forma global por una única `try/catch`.
- Registrar errores no tratados mediante mecanismos apropiados de Flutter (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) **solo** si el proyecto lo necesita y sin duplicar reportes.

## Tests de carrera y ciclo de vida

1. Solicitud A, luego B, completar B y A: el resultado visible debe ser de B.
2. Iniciar una operación y retirar pantalla/notifier: sin actualizaciones a objetos ya liberados.
3. Respuesta con error: estado, mensaje y acción de recuperación definidos.
4. Doble tap en enviar: no duplicar acciones si negocio no lo permite.
5. Editar parámetros de un widget con listener: viejo recurso desuscrito y nuevo escuchado.
6. Salir y volver a pantalla: no mantener suscripciones fantasma ni solicitudes repetidas.

Leer: https://docs.flutter.dev/testing/errors y https://docs.flutter.dev/app-architecture/design-patterns/result.
