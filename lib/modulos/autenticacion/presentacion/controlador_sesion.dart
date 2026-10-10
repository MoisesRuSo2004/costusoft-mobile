import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/notificaciones/controlador_avisos.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../../nucleo/sin_conexion/almacen_local.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../datos/fuente_remota_autenticacion.dart';
import '../datos/repositorio_autenticacion_impl.dart';
import '../dominio/estado_sesion.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/rol_usuario.dart';
import '../dominio/usuario.dart';

final proveedorRepositorioAutenticacion = Provider<RepositorioAutenticacion>(
  (ref) => RepositorioAutenticacionImpl(
    fuenteRemota: FuenteRemotaAutenticacion(
      clientePublico: ref.watch(proveedorClientePublico),
      clienteAutenticado: ref.watch(proveedorClienteHttp),
    ),
    gestorTokens: ref.watch(proveedorGestorTokens),
  ),
);

/// Estado global de la sesión. El enrutador lo escucha para redirigir.
final proveedorSesion = NotifierProvider<ControladorSesion, EstadoSesion>(ControladorSesion.new);

/// Rol de la sesión actual (`null` sin sesión).
final proveedorRolActual = Provider<RolUsuario?>((ref) {
  final sesion = ref.watch(proveedorSesion);
  return sesion is SesionActiva ? sesion.usuario.rol : null;
});

class ControladorSesion extends Notifier<EstadoSesion> {
  RepositorioAutenticacion get _repositorio => ref.read(proveedorRepositorioAutenticacion);

  @override
  EstadoSesion build() {
    final suscripcion = ref
        .watch(proveedorRepositorioAutenticacion)
        .sesionExpirada
        .listen((_) => state = const SinSesion(motivo: 'Tu sesión expiró. Inicia sesión de nuevo.'));
    ref.onDispose(suscripcion.cancel);
    return const SesionPendiente();
  }

  /// Se llama al abrir la app, después de verificar el servidor.
  Future<Resultado<void>> restaurar() async {
    final resultado = await _repositorio.restaurarSesion();
    return resultado.cuando(
      exito: (usuario) {
        state = usuario == null ? const SinSesion() : SesionActiva(usuario);
        if (usuario != null) unawaited(_prepararDatosLocales(usuario));
        return const Exito(null);
      },
      falla: Falla.new,
    );
  }

  /// Devuelve `null` si todo salió bien, o el [Fallo] para mostrarlo.
  Future<Fallo?> iniciarSesion({required String nombreUsuario, required String clave}) async {
    final resultado = await _repositorio.iniciarSesion(nombreUsuario: nombreUsuario, clave: clave);
    if (resultado case Exito(datos: final usuario)) await _prepararDatosLocales(usuario);
    return resultado.cuando(
      exito: (usuario) {
        state = SesionActiva(usuario);
        return null;
      },
      falla: (fallo) => fallo,
    );
  }

  /// "¿Olvidaste tu contraseña?": el backend envía un enlace al correo.
  Future<Resultado<String>> solicitarRecuperacionClave(String correo) =>
      _repositorio.solicitarRecuperacionClave(correo);

  Future<void> cerrarSesion() async {
    // Primero, con el token de acceso aún vigente: que no lleguen más avisos aquí.
    await ref.read(proveedorAvisos.notifier).darDeBaja();
    await _repositorio.cerrarSesion();
    await _borrarDatosLocales();
    state = const SinSesion(motivo: 'Cerraste sesión correctamente.');
  }

  /// Cierre automático tras un tiempo sin usar la app ([GuardiaInactividad]).
  /// Solo se borran los tokens: los datos sin enviar se conservan para cuando
  /// el mismo usuario vuelva a entrar, y el teléfono sigue recibiendo avisos.
  Future<void> cerrarPorInactividad() async {
    if (state is! SesionActiva) return;
    await _repositorio.cerrarSesion();
    state = const SinSesion(motivo: 'Tu sesión se cerró por inactividad. Inicia sesión de nuevo.');
  }

  /// La copia local y la bandeja de salida pertenecen a un usuario: si entra
  /// otro, se borran. También se descartan las copias viejas.
  Future<void> _prepararDatosLocales(Usuario usuario) async {
    try {
      final copia = ref.read(proveedorCopiaLocal);
      final dueno = await copia.leerDueno();
      if (dueno != usuario.id) {
        await _borrarDatosLocales();
        await copia.asignarDueno(usuario.id);
      }
      await copia.podar();
    } on Object catch (e) {
      registroApp.w('No se pudieron preparar los datos locales: $e');
    }
  }

  Future<void> _borrarDatosLocales() async {
    try {
      await ref.read(proveedorCopiaLocal).limpiar();
      await ref.read(proveedorBandejaSalida).limpiar();
    } on Object catch (e) {
      registroApp.w('No se pudieron borrar los datos locales: $e');
    }
  }
}
