# Integración con el backend SafeCore

**Fuente:** README del backend (ASP.NET Core).

**URL base:** `https://backend-safecore.onrender.com`

**Convenciones:**
- JSON en `camelCase`.
- Fechas ISO 8601 con zona horaria.
- Listas como arreglo directo, paginadas con `?page=&pageSize=` (máximo 250, sin total de registros).

## Endpoints consumidos por la app

| Método y ruta | Uso en la app | Roles |
|---|---|---|
| `POST /api/iam/auth/login` | Login y renovación de sesión (`token.accessToken`, `expiresInSeconds`, `user.roles`) | Público |
| `GET /api/iam/auth/me` | Refrescar nombre y roles al abrir la app | Autenticado |
| `GET /health/ready` | Estado del servidor y de la base de datos (login, dashboard, banner) | Público |
| `GET/POST/PUT/DELETE /api/users` | Administración de usuarios | Admin |
| `GET /api/devices` | Inventario | Admin, Op, Resp |
| `POST /api/devices` | Alta; muestra `deviceSecret` una sola vez (no se guarda) | Admin |
| `PUT /api/devices/{id}` | Editar o cambiar `connectivityStatus` | Admin |
| `DELETE /api/devices/{id}` | Baja (409 si tiene lecturas) | Admin |
| `POST /api/devices/{id}/rotate-secret` | Rotación de secreto | Admin |
| `GET /api/SensorReadings` | Telemetría reciente (páginas más nuevas, agrupadas por dispositivo) | Admin, Op, Resp |
| `POST /api/SensorReadings` | Prueba de detección | Admin, Op |
| `GET/POST /api/RiskSituations` | Riesgos activos, historial y alta manual | Lectura: Admin, Op, Resp. Alta: Admin, Op |
| `PUT /api/RiskSituations/{id}` | Reconocer, resolver o reabrir (cuerpo completo) | Admin, Op |
| `DELETE /api/RiskSituations/{id}` | Baja (409 si hay respuesta vinculada) | Admin |
| `/api/emergency/protocols` | Listar, crear, editar, activar/desactivar, eliminar | Lectura: Admin, Op, Resp. Escritura: Admin, Op. Baja: Admin |
| `/api/EmergencyResponses` | Iniciar respuesta desde un riesgo, cambiar estado | Crear: Admin, Op, Resp. Actualizar: Admin, Op |
| `/api/emergency/actions` | Registrar acciones de coordinación y su estado | Admin, Op, Resp |
| `GET /api/Notifications` | Bandeja completa | Admin, Op, Resp |
| `GET /api/Notifications/mine` | Bandeja del residente | Resident |
| `POST/PUT /api/Notifications` | Enviar notificación y marcar como entregada o fallida | Admin, Op, Resp |
| `GET/POST/PUT /api/SystemConfigurations` | Versiones de configuración y estado de sincronización | Lectura: Admin, Op. Escritura: Admin |

## Manejo de respuestas

| Código | Comportamiento |
|---|---|
| 200 / 201 / 204 | Éxito; se refrescan los datos afectados. |
| 400 | `ValidationProblemDetails`: se muestra el primer error por campo. |
| 401 | En el login, credenciales inválidas. En otras rutas, la sesión expiró y se cierra. |
| 403 | Acceso denegado; sin reintento automático. |
| 404 / 409 | Mensajes de recurso inexistente o conflicto de integridad. |
| 429 | Demasiados intentos de login (bloqueo de 15 min tras 5 fallos). |
| 503 | Base de datos no disponible; se muestra el último estado conocido. |

## Supuestos sobre campos no documentados

- Las listas pueden incluir `createdAt`; si no viene, se ordena por los campos disponibles.
- El orden de `GET /api/SensorReadings` no está documentado. La app detecta si es ascendente o descendente y localiza las páginas más recientes con búsqueda exponencial y binaria.
- Las enumeraciones desconocidas se muestran como «Sin información» sin romper la pantalla.

## Endpoints sugeridos al equipo de backend

| Propuesta | Motivo |
|---|---|
| `GET /api/SensorReadings?deviceId=&from=&sort=desc` | Evitar descargar páginas de todos los dispositivos. |
| `GET/PUT /api/SafetyThresholds` | Editar umbrales desde la app (US19). |
| `POST /api/users/{id}/reset-password` | Restablecimiento de contraseña por un administrador. |
| `POST /api/users/me/push-devices` | Registrar tokens FCM para notificaciones push. |
| `POST /api/iam/auth/refresh` | Renovar el token sin pedir la contraseña cada 15 minutos. |
| `GET /api/RiskSituations?status=Open` | Filtrar riesgos activos en el servidor. |
