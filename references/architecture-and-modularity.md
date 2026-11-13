# Arquitectura adaptativa: estructura por necesidad, no por moda

La guía oficial de Flutter explica UI (views/ViewModels) y datos (repositories/services) como arquitectura **recomendada pero adaptable**, con capa de dominio opcional. Ver https://docs.flutter.dev/app-architecture/guide.

## Primero: ¿necesita realmente una abstracción nueva?

| Síntoma observado | Solución mínima candidata | Escalar a otra capa solo si... |
|---|---|---|
| Cálculo local simple | Método puro o helper Dart | Se repite de modo importante o requiere tests independientes complejos |
| Formulario de una vista | State local / ViewModel existente | Hay reglas compartidas, cancelación/validación complejas o estado cross-screen |
| Llamada HTTP puntual | Cliente/service existente + modelo si es frontera | Hay caché, varias fuentes, reconciliación o contratos de dominio |
| Datos leídos por varias pantallas | Repositorio o notifier existente | Hay estado de carga, caching, permisos o consistencia entre features |
| Nueva feature autocontenida | Carpeta de feature con UI y lógica | Hay dependencias y API estables que justifican package interno |
| Archivos demasiado grandes | Extraer por responsabilidad y testabilidad | La longitud por sí sola **no** basta para nuevos paquetes |

## Matriz de decisión adaptativa

1. **Mantener como está** si el código es pequeño, comprensible, comprobable y poco cambiante. No exijas POO donde una función pura es mejor.
2. **Extraer método/helper** si reduce bifurcaciones, mejora nombres o evita duplicación real.
3. **Extraer widget** si delimita una responsabilidad visual, estado/rebuild o reutilización semántica. Preferir componentes claros frente a una cascada de funciones builder que ocultan dependencias.
4. **Separar ViewModel / servicio / repositorio** cuando una frontera aporta testabilidad, gestión de side effects, caché, tipado o responsabilidad bien definida. No crear las tres capas para cada endpoint.
5. **Extraer feature/package/workspace** solo cuando la cohesión interna es alta, las dependencias entre módulos están controladas, existe reutilización/ownership independiente o una frontera de publicación/compilación aporta valor medible.

Una estructura de ejemplo (NO obligatoria):

```text
lib/
  app/                        # composition root, routing, theme
  features/
    orders/
      presentation/           # views/widgets/viewmodels existentes
      data/                   # repos/services solo si aportan valor
      models/                 # contratos, invariantes
  shared/                     # poco, solo reutilización probada
```

## Estado y dependencia

- **Propiedad:** ¿Quién instancia el estado, quién lo escucha, cuándo se destruye?
- **Alcance:** estado local frente a feature/flujo frente a sesión global. No elevar todo a un singleton.
- **Dirección:** UI puede depender de contratos de datos; servicios no deberían acoplarse a `BuildContext`, rutas o widgets por conveniencia.
- **Inyección:** constructor o Provider existente, suficiente para sustituir dependencias en tests. No exigir contenedor DI externo si no aporta valor.
- **Inmutabilidad:** preservar snapshots y evitar mutaciones ocultas que no notifican.
- **Rutas:** conservar un sistema principal; una mezcla puede ser válida como transición documentada, pero no implantar una tercera librería.

## Criterios de separación de packages

Evaluar antes: número real de consumidores, estabilidad de API, ciclo de vida/versionado, dependencias de Flutter, tiempos de build, complejidad de imports/CI y acoplamiento circular. **No** crear packages para ganar apariencia de Clean Architecture.

**Regla anti-híbridos:** si se migra un patrón de estado/rutas, define orden por feature, adaptadores y retirada de la capa antigua. No dejar mezclas perpetuas sin propietario.

## Registro de decisión pequeño

```text
Decisión: mantener Provider + ViewModel para esta feature.
Evidencia: aparece en pantallas vecinas y existen tests con esa interfaz.
Alternativas: setState local, Riverpod, BLoC.
Por qué: estado compartido en este flujo; migrar un framework no reduce el riesgo de la tarea.
Coste: un ChangeNotifier y su test; no añadimos use-case/repo extra.
Revisar si: el acoplamiento dificulta pruebas o reaparece lógica duplicada.
```
