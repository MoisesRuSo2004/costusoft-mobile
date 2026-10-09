// Puente con el service worker de Firebase (solo existe en la versión web).
export 'escucha_web_otras.dart' if (dart.library.js_interop) 'escucha_web_navegador.dart';
