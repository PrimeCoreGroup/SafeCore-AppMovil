# SafeCore Mobile 2.0

[![Descargar APK](https://img.shields.io/badge/Descargar-APK%20Android-0057FF?style=for-the-badge&logo=android&logoColor=white)](https://github.com/PrimeCoreGroup/SafeCore-AppMovil/releases/latest/download/App-SafeCore.apk)
[![Última versión](https://img.shields.io/github/v/release/PrimeCoreGroup/SafeCore-AppMovil?style=for-the-badge&label=versi%C3%B3n&color=10B981)](https://github.com/PrimeCoreGroup/SafeCore-AppMovil/releases/latest)

App móvil de **SafeCore** (PrimeCore Group), conectada al backend real:
**`https://backend-safecore.onrender.com`** (ASP.NET Core + MySQL en Aiven).

Desde la app se puede:

- consultar el estado del sistema, los dispositivos ESP32 y su telemetría;
- gestionar situaciones de riesgo y coordinar respuestas de emergencia;
- leer y enviar notificaciones;
- administrar usuarios y configuración;
- verificar la cadena de detección del servidor con lecturas de prueba.

> **Seguridad física.** El backend registra telemetría y riesgos, pero **no
> acciona actuadores**. El relé, el buzzer y los LEDs los controla localmente
> el ESP32. La app nunca presenta un registro de coordinación como una
> ejecución física.

## 📲 Descargar la app

| | Enlace |
|---|---|
| **Descarga directa (Android)** | [App-SafeCore.apk](https://github.com/PrimeCoreGroup/SafeCore-AppMovil/releases/latest/download/App-SafeCore.apk) |
| **Todas las versiones** | [Releases](https://github.com/PrimeCoreGroup/SafeCore-AppMovil/releases) |

**Instalación en Android (6.0 o superior):**

1. Abre el enlace de descarga desde el navegador del teléfono.
2. Abre el archivo `App-SafeCore.apk`.
3. Si Android lo pide, permite **«Instalar apps de orígenes desconocidos»** para tu navegador.
4. Pulsa **Instalar**. Si aparece un aviso de Google Play Protect, elige **Instalar de todas formas**: es normal en apps que no vienen de la Play Store.
5. Inicia sesión con la cuenta que te entregó un administrador, o pulsa **«Explorar en modo demostración»** para probarla sin cuenta.

> La app no tiene registro público: las cuentas las crea un administrador desde **Perfil → Usuarios**.

## Novedades de la versión 2.0
