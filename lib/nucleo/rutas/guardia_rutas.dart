import '../../modulos/autenticacion/dominio/estado_sesion.dart';
import 'rutas_app.dart';

/// Decide si hay que redirigir. Devuelve la nueva ruta, o `null` para quedarse.
///
/// Reglas (las mismas del `middleware.ts` del frontend web):
/// - Mientras se restaura la sesión, solo se muestra la pantalla de carga.
/// - Sin sesión, solo se puede estar en el ingreso.
/// - Con sesión, el ingreso y la carga llevan al inicio del rol, y una ruta
///   de otro rol también (p. ej. Bodega no puede abrir `/admin/...`).
/// - [rutaSolicitada] es la ruta que se pidió antes de restaurar la sesión
///   (p. ej. un enlace directo): si es del rol, se va allí y no al inicio.
String? calcularRedireccion(EstadoSesion estado, String ubicacion, {String? rutaSolicitada}) {
  switch (estado) {
    case SesionPendiente():
      return ubicacion == RutasApp.carga ? null : RutasApp.carga;
    case SinSesion():
      return ubicacion == RutasApp.ingreso ? null : RutasApp.ingreso;
    case SesionActiva(:final usuario):
      final inicio = RutasApp.inicioDe(usuario.rol);
      final prefijo = RutasApp.prefijoDe(usuario.rol);
      bool esDelRol(String ruta) => ruta == prefijo || ruta.startsWith('$prefijo/');
      if (ubicacion == RutasApp.carga || ubicacion == RutasApp.ingreso) {
        return rutaSolicitada != null && esDelRol(rutaSolicitada) ? rutaSolicitada : inicio;
      }
      return esDelRol(ubicacion) ? null : inicio;
  }
}
