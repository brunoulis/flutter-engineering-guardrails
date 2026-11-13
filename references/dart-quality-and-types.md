# Calidad Dart: precisión, tipos y complejidad acotada

## Reglas fuertes

- Usar tipos públicos claros, `final` cuando no hay reasignación, invariantes y null-safety; reducir `dynamic` en fronteras con API externa.
- No «solucionar» null-safety con cascadas de `!`, `as` o `late` cuando no se ha probado el invariante. Validar explícitamente antes de acceder.
- No usar `catch (_){}` para esconder errores; distinguir error de red, timeout, parse, permiso, validación, cancelación y error de programación.
- No generar `toString()` para comparar estados de negocio, ni JSON como `Map` disperso por widgets.
- Poner la conversión JSON ↔ modelo en un límite probado. Introducir modelos **según valor**, no un modelo por cada campo.
- Evitar parámetros booleanos ambiguos, flags que cambian significado y funciones con responsabilidades mezcladas; preferir nombres, tipos/opciones o métodos separados si aclaran.
- Documentar **por qué**, precondiciones y decisiones sorprendentes; no repetir lo que el código expresa.
- Respetar estilo y lint existentes; no añadir un linter premium ni reglas incompatibles sin aprobación.

## Buen uso de características Dart

- `sealed class`, records, pattern matching y otras capacidades modernas **solo si el SDK mínimo del proyecto las soporta** y simplifican el diseño.
- Para estados mutuamente excluyentes, decidir entre `enum` + datos, variantes tipadas, patrón `Result` o estructura existente. Evitar estados imposibles como `isLoading == true && hasError == true` si importan semánticamente.
- Para un resultado sencillo, no crear cinco clases genéricas si `Future<T?>` con un contrato explícito resuelve bien el caso. Para errores que el consumidor debe mostrar/recuperar, valorar un resultado tipado.
- Preferir funciones puras para transformaciones deterministas, buenas para unit tests.
- En bucles intensivos, evitar asignaciones/copias innecesarias **después de medir**, no cambiar código legible por micro-optimizaciones teóricas.

## Ejemplo de frontera tipada

Antes (la UI depende de claves de servidor sin validar):

```dart
Text(response['client']['name'] ?? '')
```

Después (ilustrativo; adaptar al contrato real):

```dart
class Client {
  const Client({required this.name});
  final String name;

  factory Client.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String) {
      throw const FormatException('Expected client.name as String');
    }
    return Client(name: name);
  }
}
```

El parse debe ejecutarse al obtener datos, manejando el error en la capa propietaria, no en cada `build()`.

## Anti-patrones generados por IA

| Patrón | Por qué suele empeorar | Mejor enfoque |
|---|---|---|
| `BaseRepository<T>` genérico para un único CRUD | API falsa, complejidad sin beneficio | Servicio/repo concreto hasta tener reutilización |
| Cinco niveles de widgets para un `Text` | Dificulta lectura y pruebas | Componente útil con contrato claro |
| Extensión/helper por cada línea repetida | Fragmenta el código | Aceptar repetición trivial o abstraer comportamiento real |
| `try { ... } catch (_) { return null; }` | Borra causas e impide diagnosticar | Propagar error tipado, registrar de forma segura o mostrar feedback |
| `as dynamic` / `!` por conveniencia | Oculta contratos inválidos | Validación de borde y tipos precisos |
| Tests que comprueban implementación interna | Se rompen con refactors inocuos | Contratos observables y efectos |
| «Optimizar» cambiando toda la arquitectura | No hay relación causal ni medición | Instrumentar, reproducir, cambiar mínimo y comparar |

## Barrera de calidad (antes de dar por terminado)

1. ¿Se entiende el flujo sin navegar 8 archivos para una acción trivial?
2. ¿El nombre, tipo y acceso reflejan la responsabilidad real?
3. ¿Puede probarse el comportamiento crítico sin arrancar toda la app?
4. ¿Hay rutas de fallo y recuperación explícitas?
5. ¿Las nuevas abstracciones reducen complejidad neta?
6. ¿El código es compatible con la versión Dart del proyecto?
