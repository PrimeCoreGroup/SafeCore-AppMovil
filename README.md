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

| Área | Cambio |
|---|---|
| Backend | Integración real con la API documentada (IAM, dispositivos, lecturas, riesgos, emergencias, notificaciones, usuarios, configuración, health). |
| Roles | `Administrator`, `Operator`, `Responder` y `Resident`; la navegación y las acciones se adaptan a cada uno. |
| Sesión | Tokens de 15 min con aviso previo y **renovación sin perder la pantalla**. Manejo de 401, 403 y 429 (bloqueo por intentos). |
| Diseño | Encabezados con degradado de marca, indicadores (KPI), gráficos de telemetría con umbrales, esqueletos de carga, login rediseñado con estado del servidor en vivo. |
| Nuevas funciones | Gestión de dispositivos (alta con secreto de un solo uso, rotación de secreto, estados), prueba de detección, protocolos, respuestas y acciones de emergencia, bandeja y envío de notificaciones, administración de usuarios, versiones de configuración, historial de riesgos con filtros, vista específica para residentes. |
| Demo | Modo demostración que reproduce el backend (roles, 403, 409, validaciones y motor de detección). Se activa desde el login. |

## 1. Requisitos previos

- Flutter 3.27 o superior (canal stable).
- Android Studio con SDK 34+ y un emulador, o un teléfono Android 6.0+.
- macOS con Xcode 15+ y CocoaPods para compilar en iOS.

## 2. Instalación de Flutter

1. Descarga Flutter desde <https://docs.flutter.dev/get-started/install>.
2. Agrega `flutter/bin` al `PATH`.
3. Ejecuta `flutter doctor` y resuelve lo que indique.

## 3. Instalación y ejecución rápida

```bash
cd safecore_mobile
flutter pub get
flutter run          # se conecta a https://backend-safecore.onrender.com
```

Si no tienes un emulador conectado:

1. Abre Android Studio → **Device Manager**.
2. Crea e inicia un dispositivo.
3. Ejecuta `flutter devices` para confirmar que aparece.

Como alternativa, conecta un teléfono con depuración USB.

Si tu versión de Flutter genera conflictos en `android/` o `ios/`, regenéralas sin tocar el código:

```bash
flutter create . --platforms=android,ios --org pe.primecore --project-name safecore_mobile
```

## 4. Configuración del backend

La URL del backend de Render **ya viene configurada por defecto**. Para cambiarla, copia `.env.example` a `.env`, edítalo y ejecuta:

```bash
flutter run --dart-define-from-file=.env
```

Para un backend local (`dotnet run`) desde el emulador Android:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000 --dart-define=ALLOW_INSECURE_HTTP=true --dart-define=APP_ENV=development
```

**La app nunca debe contener credenciales.** No coloques cadenas de conexión de la base de datos, la clave JWT ni contraseñas en el código ni en `.env`. La app solo necesita la URL pública del backend.

**Cuentas.** No hay registro público. El primer administrador lo crea el backend (`BootstrapAdmin`). Después, ese administrador crea las demás cuentas desde **Perfil → Usuarios**.

## 5. Configuración de Firebase (opcional)

Con `FIREBASE_ENABLED=false` la app funciona completa. El backend actual guarda las notificaciones, pero **no las entrega** por push, correo ni SMS. La bandeja de la app se actualiza automáticamente (cada 30 s) y muestra un aviso emergente cuando llega una notificación nueva.

Para preparar las notificaciones push:

1. Ejecuta `dart pub global activate flutterfire_cli`.
2. Ejecuta `flutterfire configure` (genera `lib/firebase_options.dart`, ignorado por git).
3. En `lib/shared/services/push_notification_service.dart`, usa `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
4. Ejecuta con `FIREBASE_ENABLED=true`. Falta además un endpoint del backend para registrar el token del dispositivo (ver `docs/API_CONTRACTS.md`).

## 6. Ejecución en Android

¿Solo quieres instalarla? Descarga el APK listo desde la sección [Descargar la app](#-descargar-la-app).

Para ejecutarla o compilarla desde el código:

```bash
flutter run
flutter build apk --release
```

El APK compilado queda en `build/app/outputs/flutter-apk/app-release.apk`.

El manifiesto incluye los permisos `INTERNET`, `ACCESS_NETWORK_STATE` y `POST_NOTIFICATIONS`. También fija `allowBackup=false` y `usesCleartextTraffic=false`. Configura tu propia firma antes de publicar en Google Play.

## 7. Ejecución en iOS

```bash
cd ios && pod install && cd ..
flutter run -d <simulador>
```

## 8. Modo demostración

En el login, pulsa **«Explorar en modo demostración»**. También puedes compilar con `--dart-define=DEMO_MODE=true`.

Todas las cuentas usan la contraseña `Demo-2026!`. Los datos son ficticios y se identifican con el distintivo **DEMO**.

| Cuenta | Rol |
|---|---|
| `admin@demo.safecore.pe` | Administrador |
| `operador@demo.safecore.pe` | Operador |
| `respondedor@demo.safecore.pe` | Respondedor |
| `residente@demo.safecore.pe` | Residente |

El modo demo replica el backend:

- Permisos por rol, con respuestas 403.
- Conflictos 409 (serial duplicado, dispositivo con lecturas, último administrador).
- Validaciones de lecturas.
- Motor de detección: ≥ 40 °C, gas digital o +100 ADC, impacto > 200 cuentas, -127 °C, con deduplicación y resolución automática.

Para probar el modo offline: **Perfil → Simular pérdida de conexión**.

## 9. Funciones por rol

| Función | Admin | Operador | Respondedor | Residente |
|---|:-:|:-:|:-:|:-:|
| Dashboard del sistema, dispositivos, telemetría, riesgos, emergencias | ✓ | ✓ | ✓ | — |
| Reconocer, resolver o registrar riesgos | ✓ | ✓ | — | — |
| Iniciar respuestas y registrar acciones | ✓ | ✓ | ✓ | — |
| Cambiar el estado de una respuesta | ✓ | ✓ | — | — |
| Protocolos (crear, editar, activar) | ✓ | ✓ | — | — |
| Prueba de detección (publicar lecturas) | ✓ | ✓ | — | — |
| Alta, edición, rotación de secreto y baja de dispositivos | ✓ | — | — | — |
| Usuarios | ✓ | — | — | — |
| Configuración (ver / editar) | ✓ / ✓ | ✓ / — | — | — |
| Notificaciones: todas y envío | ✓ | ✓ | ✓ | — |
| Notificaciones propias | ✓ | ✓ | ✓ | ✓ |

La app oculta lo no permitido, pero el backend valida cada operación y su respuesta 403 es la fuente de verdad.

## 10. Estructura del proyecto

```text
lib/
├── core/            config, errores, red (Dio + JWT + paginación), router por rol,
│                    seguridad, caché SQLite, tema, widgets y visuales
├── features/
│   ├── authentication/  login, sesión 15 min, renovación, ayuda de acceso
│   ├── dashboard/       evaluación del sistema, health, vista de residente
│   ├── devices/         inventario, detalle con telemetría, gestión y secretos
│   ├── telemetry/       lecturas, evaluador de riesgos, prueba de detección
│   ├── risks/           activos, historial con filtros, detalle y acciones
│   ├── emergency/       protocolos, respuestas, acciones de coordinación
│   ├── notifications/   bandeja, envío, preferencias locales
│   ├── users/           administración de cuentas
│   ├── configuration/   versiones de configuración y umbrales
│   └── profile/
└── shared/          estados, providers y servicios (push, demo)
```

Cada módulo sigue Clean Architecture:

- `domain`: entidades y reglas en Dart puro.
- `data`: mappers, fuente remota, fuente demo y repositorio con caché.
- `presentation`: páginas y providers de Riverpod.

## 11. Pruebas

```bash
flutter analyze
flutter test
flutter test integration_test -d <dispositivo>
```

Las pruebas de contrato usan los ejemplos JSON del README del backend:

- **Autenticación y errores HTTP:** login, 401, 403, 404, 409, 429, 503 y `ValidationProblemDetails`.
- **Paginación:** sin total de registros.
- **Reglas de negocio:** matriz de roles, evaluador de umbrales, evaluación del sistema e historial con filtros.
- **Integridad y detección:** reglas de integridad y pruebas de detección.
- **Widgets:** login, navegación por rol, modo offline y componentes.

## Limitaciones conocidas

- El backend no expone endpoints para editar los umbrales (`SafetyThresholds`), para restablecer contraseñas ni para registrar tokens push. La app muestra los umbrales por defecto como referencia.
- La API de lecturas no filtra por dispositivo. La app descarga las páginas más recientes y las agrupa localmente.
- Swagger solo está activo en `Development`; los contratos se tomaron del README del backend.
