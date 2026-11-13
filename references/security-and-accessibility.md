# Seguridad, privacidad y accesibilidad para Flutter

## Seguridad basada en superficies reales

- **Tokens y secretos:** no poner secretos de servidor en `--dart-define`, assets, `pubspec.yaml` o cliente Flutter como si fueran confidenciales; un binario o cliente web puede exponerlos. Definir credenciales seguras en backend.
- **Autorización:** validaciones UI no sustituyen validación/permiso de servidor. No aceptar IDs de recurso como prueba de permisos.
- **Almacenamiento:** seleccionar mecanismo apropiado para plataforma y sensibilidad; no persistir tokens sensibles en almacenamiento web plano sin evaluar riesgos.
- **Red:** comprobar HTTP status/timeout/errores, parsear forma del JSON y limitar datos en logs. No desactivar TLS ni aceptar certificados sin validación.
- **Links y navegación:** validar URLs/deep links antes de ejecutar acciones y respetar auth/session de ruta.
- **Logs:** no registrar contraseñas, tokens, datos personales o cuerpos sensibles; no lanzar errores técnicos crudos a usuarios.
- **Dependencias:** verificar mantenimiento, license, compatibilidad, necesidad y permisos antes de añadir un paquete.

## Accesibilidad y usabilidad

Ver https://docs.flutter.dev/ui/accessibility.

- Texto legible a escala del SO/navegador, contraste apropiado y adaptación a contenido largo.
- Semantics/labels/hints para controles solo-ícono e interacciones no obvias.
- Foco visible y orden de tabulación correcto; escape/volver/cerrar accesible con teclado en Web/desktop.
- Áreas táctiles adecuadas cuando es una app móvil, sin sacrificar densidad en desktop si hay otra interacción accesible.
- No usar exclusivamente color para representar estado (semáforos), especialmente en avisos/errores. Añadir texto/ícono semántico.
- Evitar bloqueo con overlays/modales sin forma de cerrarlos o recuperar foco.
- Probar lector de pantalla/semantics cuando es una parte crítica del flujo y la plataforma lo permite.

## Rails de revisión

Las alertas de seguridad y accesibilidad con impacto demostrado tienen prioridad sobre los ajustes de naming o preferencias de estilo. No sugerir cambios de paquetes/autenticación a ciegas: inspeccionar plataforma, backend y contratos reales.
