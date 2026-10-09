# CostuSoft Móvil

App en Flutter del sistema **CostuSoft Control**. Consume únicamente el backend
Spring Boot (`costusoft-backend-core`). El diseño completo está en
`../CostuSoft_Movil_Documento_Diseno.docx`.

> **Convención:** todo el código propio está en español (carpetas, archivos, clases,
> funciones y variables). Solo quedan en inglés los nombres que vienen de Flutter o de
> las librerías (`Widget`, `build`, `Dio`…).

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | 3.47.6 (stable) · Dart 3.13 |
| Navegador | Google Chrome (las pruebas se hacen en web) |
| Pub cache | `PUB_CACHE=C:\pub-cache` (ruta sin espacios) |

## Ejecutar (web)

Con el backend corriendo en `localhost:8080` (su CORS permite `http://localhost:5000`):

```powershell
flutter pub get

# Desarrollo con recarga en caliente (hot reload: tecla r)
flutter run -d chrome --web-port 5000 --dart-define-from-file=env/desarrollo.json

# Contra producción (Render)
flutter run -d chrome --web-port 5000 --dart-define-from-file=env/produccion.json
```

Para ver la app con tamaño de celular: en Chrome, `F12` → icono de dispositivo
(`Ctrl+Shift+M`) → elegir p. ej. "Pixel 7".

## Compilar el APK (Android)

```powershell
$env:JAVA_HOME = "C:\jdk-17.0.16"
flutter build apk --release --dart-define-from-file=env/produccion.json
# → build/app/outputs/flutter-apk/app-release.apk
```

**Firma de release.** Todas las versiones deben firmarse con la misma llave; si no,
Android no deja actualizar la app instalada. La llave (`.jks`) y sus contraseñas son
**secretas** y viven fuera del repositorio. En `android/local.properties` (propio de
cada PC, ignorado por Git) se indica dónde están:

```properties
costusoft.firma=C:/dev/costusoft/secretos/key.properties
```

Sin esa línea el APK se firma con la llave de depuración. Antes de cada entrega,
sube el número de versión en `pubspec.yaml` (`version: 1.0.1+2`: Android compara el `+N`).

## Notificaciones push

Firebase Cloud Messaging (proyecto `costusoft`) avisa al rol Institución cuando su
pedido pasa a **Listo para entrega**. Configuración pública en
`lib/nucleo/notificaciones/opciones_firebase.dart`, `android/app/google-services.json`
y `web/firebase-messaging-sw.js`. La credencial del backend (cuenta de servicio) es
secreta y no está aquí: en el backend va en `FIREBASE_CREDENTIALS_JSON`.

## Calidad

```powershell
dart format lib test
dart analyze
flutter test
```

## Estructura

```
lib/
├── main.dart                 arranque
├── aplicacion.dart           MaterialApp: tema, rutas, idioma
├── nucleo/                   configuracion · errores · notificaciones · red · rutas · sesion · sin_conexion · tema · utilidades
├── compartido/widgets/       componentes reutilizables
└── modulos/                  carga · autenticacion · tablero · inventario · ia · pedidos · bodega · institucion · perfil
```

Cada módulo sigue Clean Architecture: `datos/` → `dominio/` ← `presentacion/`.

| Concepto | Nombre en el código |
|---|---|
| Resultado de una operación | `Resultado<T>` = `Exito` \| `Falla` |
| Error de dominio | `Fallo` (`FalloRed`, `FalloValidacion`, `FalloPermiso`…) |
| Envoltorio del backend | `RespuestaApi<T>`, `PaginaApi<T>` |
| Proveedores Riverpod | `proveedor…` (p. ej. `proveedorClienteHttp`) |

## Fases

| Fase | Estado |
|---|---|
| 0 · Diseño y entorno | ✅ |
| 1 · Fundaciones (arquitectura, entornos, tema, rutas, red, errores) | ✅ |
| 2 · Autenticación y sesión (JWT, renovación, guardas por rol, perfil, cierre) | ✅ (biometría: al compilar para celular) |
| 3 · Admin + IA — Inicio ✅ · Inventario ✅ · IA ✅ | ✅ |
| 4 · Pedidos (paginación en servidor, filtros, detalle, flujo de estados, cancelación) | ✅ |
| 5 · Bodega + QR (cola de trabajo, verificar entradas/salidas, cola de pedidos paginada, inventario de consulta, historial paginado, escáner QR, etiquetas QR) | ✅ |
| 6 · Offline-first | ⏳ |
| 7 · Notificaciones push (FCM: aviso de pedido listo al colegio) | ✅ |
| 8 · Institución (mis pedidos, seguimiento con línea de tiempo, asistente IA) | ✅ |
