import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Al tocar un aviso con la app abierta en otra pestaña, el service worker
/// (`web/firebase-messaging-sw.js`) envía la ruta del pedido y la app navega.
void escucharRutasDelServiceWorker(void Function(String ruta) alAbrir) {
  web.window.navigator.serviceWorker.addEventListener(
    'message',
    (web.MessageEvent evento) {
      final datos = evento.data.dartify();
      if (datos is Map && datos['tipo'] == 'abrir-ruta' && datos['ruta'] is String) {
        alAbrir(datos['ruta'] as String);
      }
    }.toJS,
  );
}
