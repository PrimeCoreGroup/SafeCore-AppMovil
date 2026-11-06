# Decisiones técnicas (versión 2.0)

1. **El backend real manda.** El contrato propuesto en la versión 1 se reemplazó por el README del backend. Se retiraron los módulos sin soporte en el servidor: inmuebles, umbrales editables, mantenimiento y simulacros de actuadores. Las funciones equivalentes se reconstruyeron sobre recursos reales (dispositivos, riesgos, emergencias y configuración).

2. **Sin credenciales en la app.** La app solo conoce la URL pública. Las cadenas de conexión, la clave JWT y las contraseñas de arranque viven en Render y nunca se incluyen en el binario.

3. **Registro frente a ejecución física.** El backend no envía comandos a actuadores.
   - Las acciones de emergencia se presentan como registros de coordinación; «Completada» significa que una persona la registró así.
   - La **prueba de detección** solo indica éxito cuando el servidor devuelve el riesgo creado o resuelto. Si el servidor no responde, termina como «Sin confirmación».

4. **Evaluación honesta del estado.** «Sin riesgos activos» exige conexión, backend listo, datos frescos, dispositivos registrados y telemetría reciente. Un riesgo urgente conocido prevalece y se muestra aunque los datos sean del último estado conocido.

5. **Sesión de 15 minutos sin refresh token.** La app avisa 2 minutos antes y permite renovar con la contraseña sin perder la navegación. Nunca guarda la contraseña.

6. **Roles globales.** El backend no tiene inmuebles: los roles son por usuario. La navegación cambia por rol; el residente ve Inicio, Avisos y Perfil, porque el backend solo le permite `/api/Notifications/mine`.

7. **Paginación sin total.** Se usa `fetchAllPages` para recursos acotados y `fetchNewest` para la telemetría.

8. **Offline.** Se usa la caché SQLite del último estado conocido, las acciones remotas se deshabilitan y se resincroniza al reconectar. Ninguna acción se encola para enviarse después.

9. **Modo demostración en tiempo de ejecución.** Permite evaluar la app sin cuenta, replicando las reglas del backend. Al cerrar sesión se vuelve al modo de compilación.

10. **Umbrales.** Se muestran los valores por defecto documentados del backend, que replican el firmware. No son editables hasta que exista un endpoint para ello.
