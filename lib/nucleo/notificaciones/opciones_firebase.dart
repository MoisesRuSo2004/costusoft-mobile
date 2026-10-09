import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Proyecto Firebase `costusoft` (solo para notificaciones push).
///
/// Estos valores identifican la app ante Firebase y no son secretos: Firebase
/// los diseñó para ir dentro de la app. Lo secreto es la cuenta de servicio
/// del backend, que nunca está en este repositorio.
/// Android los toma de `android/app/google-services.json`; web, de aquí.
abstract final class OpcionesFirebase {
  static FirebaseOptions? get actual => switch (defaultTargetPlatform) {
    _ when kIsWeb => web,
    TargetPlatform.android => android,
    // iOS necesita GoogleService-Info.plist (no se distribuye por ahora).
    _ => null,
  };

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCie1c_9PVz5q4iG-JO30yeV3hkkK8q2G0',
    appId: '1:980007827043:web:87efb5fd93bb2f59b12a56',
    messagingSenderId: '980007827043',
    projectId: 'costusoft',
    authDomain: 'costusoft.firebaseapp.com',
    storageBucket: 'costusoft.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBvtgZjvwrVI_vibjWqkWLK6zDy8__qiF4',
    appId: '1:980007827043:android:04b4b78a8b1ad847b12a56',
    messagingSenderId: '980007827043',
    projectId: 'costusoft',
    storageBucket: 'costusoft.firebasestorage.app',
  );

  /// Clave pública "web push" (VAPID) para obtener el token en el navegador.
  static const claveVapidWeb =
      'BAOzRuNXhWXhxT9XF69IETQSUxb-NsFQi10GQ3QblSU9n8hOGqNYl_CrCkW4tLMv2zpr7fNFE8kgv7pG_9_7x5s';
}
