# Rendimiento: Flutter Web, desktop y UI reactiva

Objetivo: **optimizar donde exista un problema**, no convertir todos los widgets a micro-optimizaciones. Guía oficial: https://docs.flutter.dev/perf/best-practices.

## Método obligatorio para afirmaciones de mejora

1. **Reproducir:** caso de uso, dispositivo/navegador y perfil de datos, versión/release mode apropiados.
2. **Medir baseline:** Flutter DevTools Performance/Memory, tiempo por frame, timeline CPU, reconstrucciones, solicitudes, memory snapshots; seleccionar métrica que mida el problema.
3. **Formular hipótesis:** por ejemplo, lista eager construye miles de elementos o `notifyListeners` provoca trabajo innecesario.
4. **Cambiar lo mínimo:** una región de rebuild, un memo/caché con invalidación, una consulta, un list builder.
5. **Comparar A/B:** misma máquina, datos, escenario y modo; reportar resultados reales o **no medido**.
6. **Valorar coste:** latencia/CPU/RAM/complexidad y recursos liberados.

## Reglas técnicas

- `build()` puede ejecutarse frecuentemente; no bloquearlo con parsing grande, I/O ni cómputos costosos repetitivos.
- Usar `ListView.builder`/`SliverList` u otros builders perezosos para muchas filas; no usar `Column(children: thousands)`.
- Localizar el estado reactivo en el subárbol consumidor. `Consumer`/`Selector`/equivalentes ayudan cuando el profiling muestra rebuild excesivo, no por obligación.
- Mantener objetos de `Future`/streams y controladores según lifecycle, evitando nuevas requests sin motivo en rebuilds.
- `const` mejora expresividad y puede evitar trabajo, pero no reemplaza diseño ni profiling.
- Tener cuidado con `Opacity`, clipping, `saveLayer`, intrinsic layout, sombras o filtros en animaciones; comprobar si son la causa real.
- Seleccionar claves estables en listas de elementos que cambian de orden.
- Evitar cachés sin límites ni invalidación, incluso cuando reducen CPU: pueden subir RAM y mostrar datos obsoletos.
- Medir la situación real antes de usar isolates; el coste de serialización y arranque puede superar ahorro.

## Flutter Web / paneles de gestión

- Estado de URL, refresh/back/forward, filtros y deep links deben funcionar con el router real.
- Probar layouts con zoom, navegación de teclado, tamaños de ventana y text scaling.
- Medir el coste de render de tablas de gran tamaño, listas virtualizadas, descargas, imágenes y parseo JSON.
- Evitar cálculos pesados en el hilo UI; no prometer menor RAM al mover operaciones a otra capa si siguen viviendo en el mismo proceso.
- No usar un `MediaQuery.sizeOf(context).width` de toda la pantalla cuando lo que importa es el ancho de un panel limitado por el padre.
- En desktop: probar resize, foco, soporte de ratón, atajos y distribución DPI.

## Evidencia que debe devolver el agente

```text
Hipótesis: Widget X rehace 400 filas por cambio de filtro.
Baseline: [medición real; si no, no medido].
Cambio: builder perezoso + estado localizado.
Después: [medición real].
Riesgos: scroll, selección, accesibilidad, ordering.
Tests: widget test 0/1/muchas filas + interacción.
```

Nunca afirmar «30% más rápido» por lectura estática ni por número de líneas reducido.
