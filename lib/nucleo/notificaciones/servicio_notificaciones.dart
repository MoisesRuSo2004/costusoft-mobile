import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utilidades/registro_app.dart';
import 'opciones_firebase.dart';

/// Situación de los avisos push en este dispositivo.
enum EstadoAvisos {
  /// Sin Firebase en esta plataforma, o el rol no recibe avisos.
  noDisponible,

  /// El usuario aún no decide: se le ofrece activarlos.
  sinPreguntar,
  activos,

  /// Los rechazó; solo se pueden reactivar desde el sistema o el navegador.
  bloqueados,
}

/// Inicia Firebase al abrir la app. Si falla, la app funciona igual sin avisos.
Future<bool> iniciarFirebase() async {
  final opciones = OpcionesFirebase.actual;
  if (opciones == null) return false;
  try {
    await Firebase.initializeApp(options: opciones);
    return true;
  } on Object catch (e) {
    registroApp.w('Firebase no disponible; la app sigue sin avisos push: $e');
    return false;
  }
}

/// Permiso, token del dispositivo y su registro en el backend
/// (`/api/notificaciones/dispositivos`).
class ServicioNotificaciones {
  ServicioNotificaciones(this._cliente);

  final Dio _cliente;
  String? _tokenRegistrado;

  FirebaseMessaging get _mensajeria => FirebaseMessaging.instance;

  static String get _plataforma => kIsWeb ? 'WEB' : (defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID');

  static EstadoAvisos _desdePermiso(AuthorizationStatus permiso) => switch (permiso) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => EstadoAvisos.activos,
    AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => EstadoAvisos.bloqueados,
    AuthorizationStatus.notDetermined => EstadoAvisos.sinPreguntar,
  };

  Future<EstadoAvisos> consultarPermiso() async =>
      _desdePermiso((await _mensajeria.getNotificationSettings()).authorizationStatus);

  /// Muestra el diálogo del sistema o del navegador.
  Future<EstadoAvisos> pedirPermiso() async =>
      _desdePermiso((await _mensajeria.requestPermission()).authorizationStatus);

  Future<String?> _token() => _mensajeria.getToken(vapidKey: kIsWeb ? OpcionesFirebase.claveVapidWeb : null);

  /// Registra (o actualiza) el token de este dispositivo para el usuario en sesión.
  Future<void> registrarDispositivo() async {
    final token = await _token();
    if (token == null || token == _tokenRegistrado) return;
    await _cliente.post<void>('/api/notificaciones/dispositivos', data: {'token': token, 'plataforma': _plataforma});
    _tokenRegistrado = token;
  }

  /// Al cerrar sesión: el backend deja de avisar a este dispositivo.
  Future<void> darDeBaja() async {
    final token = _tokenRegistrado;
    _tokenRegistrado = null;
    if (token == null) return;
    await _cliente.delete<void>('/api/notificaciones/dispositivos', data: {'token': token});
  }

  /// Aviso de prueba a los dispositivos del usuario en sesión.
  Future<int> enviarPrueba() async {
    final respuesta = await _cliente.post<Map<String, dynamic>>('/api/notificaciones/prueba');
    return (respuesta.data?['data'] as num?)?.toInt() ?? 0;
  }

  /// Firebase renueva el token cada cierto tiempo.
  Stream<String> get tokenRenovado => _mensajeria.onTokenRefresh;
}
