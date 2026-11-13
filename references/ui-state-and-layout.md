# Widgets, estado, formularios, routing y diseño responsive

## Stateless ≠ superior; Stateful ≠ mala práctica

La elección depende de **quién posee y modifica el estado**, no de dogmas:

| Necesidad | Candidato razonable |
|---|---|
| UI pura a partir de parámetros | `StatelessWidget` |
| `AnimationController`, `TextEditingController`, foco, tabs, estado efímero | `StatefulWidget` con lifecycle claro |
| Estado de negocio de una pantalla ya gestionada con Provider/ViewModel | Widget consumidor + ViewModel existente |
| Estado global compartido por varias features | Patrón global ya establecido, con propietario y alcance documentados |

No muevas un formulario que funciona con Provider/ViewModel a `StatefulWidget` solo para eliminar `notifyListeners`, ni obligues a que cada widget sea stateless cuando requiere recursos propios.

## Estado reactivo y reconstrucciones

- Elegir una única fuente de verdad. Evitar duplicar `controller.text`, `selectedValue` y `viewModel.selectedValue` sin sincronización definida.
- Con Provider: observar en widgets que necesitan actualizarse (`context.watch`, `Consumer` o `Selector` cuando ayude), acceder a acciones con `context.read` según el momento; respetar el ámbito del provider.
- `ChangeNotifier`: notificar transiciones observables, no cada instrucción; evitar que un `notifyListeners()` tras dispose use un objeto terminado.
- `setState`: para estado efímero propiedad de `State` y cuando afecta a un subárbol delimitado. No propagar invalidación a toda la pantalla por un spinner local.
- En Riverpod/BLoC, mantener su convención concreta; no mezclar patrones para satisfacer una preferencia del agente.
- Para formularios: validación de campos, envío duplicado, estados disabled/loading, foco, errores visibles y preservación de datos al fallar.

## Estructura UI

- `build()` debe ser una descripción de UI sin I/O, escrituras a DB, navegación automática u operaciones largas no memorizadas.
- No inicializar una nueva petición asíncrona en cada rebuild; crear y retener Future/controlador fuera del build cuando la semántica lo requiera.
- Descomponer widgets por responsabilidad conceptual o región de rebuild; no extraer piezas triviales por longitud.
- Usar `const` cuando sea válido y útil, no como obsesión cosmética; no sobreescribir `operator ==` de `Widget` para «optimizar».
- `Key` cuando da identidad estable (listas reordenables, estados preservados, tests), no claves aleatorias cada build.

## Responsive Flutter Web y desktop

- Analizar constraints mediante `LayoutBuilder`, `MediaQuery` y widgets flexibles según contexto; usar diseño basado en ancho disponible del contenedor cuando la pantalla está embebida.
- No inventar breakpoints comunes ni cambiar uno existente sin evidencias visuales/producto.
- Probar anchos compactos, transición de breakpoint, medianos/anchos, altura limitada, zoom navegador y escala del texto.
- Evitar anchuras rígidas y contenido inaccesible, overflows, scrolls anidados conflictivos y problemas por teclado.
- `kIsWeb` discrimina runtime web, **no** ancho de viewport.
- Si hay tablas/paneles grandes, escoger scroll/constricción/virtualización según usabilidad, no «reducir fuente hasta caber».

## Navegación

- Identificar el router principal y sus garantías: parámetros, deep links, historial web, back-stack, guards y navegación tras operaciones `await`.
- Prohibido mezclar bibliotecas de rutas sin comprender el stack existente; migración solo por alcance decidido y test de navegación.
- En los callbacks async que usan `BuildContext` después de un `await`, comprobar `context.mounted` cuando proceda, y contemplar respuestas obsoletas.

## Lista de pruebas UI orientativas

- Render: carga/error/vacío/éxito y ausencia de datos.
- Eventos: tap, form submission, teclado, selección, navegación y volver.
- Ciclo: salir de pantalla durante una petición, abrir dos solicitudes, recargar, cambiar datos del widget padre.
- Adaptación: ancho antes/después del breakpoint, scroll, tamaño de texto y foco visible.
- Accesibilidad: nombres/semantics, orden de navegación, contraste y tamaño interactivo aplicable.
