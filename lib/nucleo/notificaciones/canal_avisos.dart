import 'dart:async';
import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utilidades/registro_app.dart';

/// Notificaciones del sistema en Android, como las de cualquier app.
///
/// - Crea el canal "avisos_costusoft" con importancia alta: el aviso aparece
///   arriba de la pantalla, suena y vibra. El backend envía los push a este
///   canal (`EnvioPush.CANAL_ANDROID`); con la app cerrada o en segundo plano
///   Android los muestra solo.
/// - Con la app abierta, Firebase no muestra nada por sí mismo: [mostrar]
///   publica el mismo aviso en la barra de notificaciones.
abstract final class CanalAvisos {
  static const id = 'avisos_costusoft';
  static const _nombre = 'Avisos de CostuSoft';
  static const _descripcion = 'Pedidos listos y otros avisos importantes.';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _listo = false;

  /// Llamado al tocar un aviso mostrado con la app abierta (recibe el
  /// `pedidoId` como texto, o vacío).
  static void Function(String? pedidoId)? alTocar;

  static bool get _esAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Se llama en `main()`, antes de que llegue cualquier push.
  static Future<void> iniciar() async {
    if (!_esAndroid || _listo) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notificacion')),
        onDidReceiveNotificationResponse: (respuesta) => alTocar?.call(respuesta.payload),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              id,
              _nombre,
              description: _descripcion,
              importance: Importance.high,
            ),
          );
      _listo = true;
    } on Object catch (e) {
      registroApp.w('No se pudo preparar el canal de avisos: $e');
    }
  }

  /// La app se abrió tocando un aviso mostrado por [mostrar].
  static Future<String?> pedidoDelAvisoInicial() async {
    if (!_listo) return null;
    final detalles = await _plugin.getNotificationAppLaunchDetails();
    return detalles?.didNotificationLaunchApp == true ? detalles?.notificationResponse?.payload : null;
  }

  /// Muestra en la barra del sistema un push recibido con la app abierta.
  /// Devuelve `false` si no se pudo (web, o canal sin preparar).
  static bool mostrar(RemoteMessage mensaje, {String? pedidoId}) {
    final aviso = mensaje.notification;
    if (!_listo || aviso == null) return false;
    unawaited(
      _plugin.show(
        id: mensaje.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: aviso.title ?? 'CostuSoft',
        body: aviso.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            id,
            _nombre,
            channelDescription: _descripcion,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notificacion',
            color: Color(0xFF0891B2),
          ),
        ),
        payload: pedidoId,
      ),
    );
    return true;
  }
}
