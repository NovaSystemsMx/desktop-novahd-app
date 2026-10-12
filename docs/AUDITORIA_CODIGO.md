# Auditoría de código — Nova Hub Downloader

Fecha: 2026-10-06. Ejes: arquitectura y optimización.
Puntos 1, 2, 3, 5, 6 y 9 realizados; 7 y 8 evaluados y cerrados;
10 sin acción. Queda pendiente:

## Pendientes

### 1. Diagnóstico en `catch (_) {}` (antes punto 4)
~20 sitios tragan errores sin dejar rastro. Falta decidir: consola
in-app en sesión vs archivo de logs (ver conversación 2026-10-06:
se propuso `AppLogService` + panel colapsable, y volcado a
`session.log` como fase 2).

**Solución propuesta:** `AppLog.info/warn/error(tag, msg)` con buffer
de 300 líneas; los `catch` actuales loguean en vez de silenciar.
