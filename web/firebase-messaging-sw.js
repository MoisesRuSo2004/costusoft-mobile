// Service worker de Firebase Cloud Messaging para la versión web.
// Recibe los avisos con la app cerrada o en segundo plano; como el mensaje trae
// "notification", Firebase lo muestra solo.
// La versión del SDK debe coincidir con la de firebase_core_web
// (supportedFirebaseJsSdkVersion).
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

// Al tocar el aviso: enfoca la app (o la abre) en el seguimiento del pedido.
// Se registra ANTES de iniciar Firebase para atender el clic primero.
self.addEventListener('notificationclick', (event) => {
  const datos = (event.notification.data && event.notification.data.FCM_MSG && event.notification.data.FCM_MSG.data) || {};
  event.stopImmediatePropagation();
  event.notification.close();
  const ruta = datos.pedidoId ? '/institucion/pedidos/' + datos.pedidoId : '/institucion/pedidos';
  const origen = self.location.origin;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((ventanas) => {
      const app = ventanas.find((v) => v.url.startsWith(origen));
      if (app) {
        // La app escucha este mensaje y navega (escucha_web.dart).
        app.postMessage({ tipo: 'abrir-ruta', ruta: ruta });
        return app.focus();
      }
      return clients.openWindow(origen + '/#' + ruta);
    }),
  );
});

firebase.initializeApp({
  apiKey: 'AIzaSyCie1c_9PVz5q4iG-JO30yeV3hkkK8q2G0',
  authDomain: 'costusoft.firebaseapp.com',
  projectId: 'costusoft',
  storageBucket: 'costusoft.firebasestorage.app',
  messagingSenderId: '980007827043',
  appId: '1:980007827043:web:87efb5fd93bb2f59b12a56',
});

firebase.messaging();
