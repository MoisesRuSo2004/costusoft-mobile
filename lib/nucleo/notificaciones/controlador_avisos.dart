import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modulos/autenticacion/dominio/rol_usuario.dart';
import '../../modulos/autenticacion/presentacion/controlador_sesion.dart';
import '../../modulos/bodega/presentacion/proveedores_bodega.dart';
import '../../modulos/institucion/presentacion/proveedores_institucion.dart';
import '../red/cliente_http.dart';
import '../rutas/enrutador_app.dart';
import '../rutas/rutas_app.dart';
import '../utilidades/registro_app.dart';
import 'canal_avisos.dart';
import 'escucha_web.dart';
import 'servicio_notificaciones.dart';

/// `true` si Firebase se inició en `main()` (se sobreescribe allí).
final proveedorFirebaseDisponible = Provider<bool>((ref) => false);

final proveedorServicioNotificaciones = Provider<ServicioNotificaciones>(
  (ref) => ServicioNotificaciones(ref.watch(proveedorClienteHttp)),
);

/// Mensajero global para mostrar los avisos que llegan con la app abierta.
final llaveMensajeroApp = GlobalKey<ScaffoldMessengerState>();

/// Avisos push para los roles de [rolesConAvisos].
final proveedorAvisos = AsyncNotifierProvider<ControladorAvisos, EstadoAvisos>(ControladorAvisos.new);

class ControladorAvisos extends AsyncNotifier<EstadoAvisos> {
  ServicioNotificaciones get _servicio => ref.read(proveedorServicioNotificaciones);

  @override
  Future<EstadoAvisos> build() async {
    final rol = ref.watch(proveedorRolActual);
    if (!ref.watch(proveedorFirebaseDisponible) || !rolesConAvisos.contains(rol)) return EstadoAvisos.noDisponible;

    final estado = await _servicio.consultarPermiso();
    if (estado == EstadoAvisos.activos) await _registrar();
    return estado;
  }

  /// Desde el botón "Activar avisos": el navegador exige un gesto del usuario.
  Future<void> activar() async {
    state = const AsyncLoading();
    final estado = await _servicio.pedirPermiso();
    if (estado == EstadoAvisos.activos) await _registrar();
    state = AsyncData(estado);
  }

  Future<void> _registrar() async {
    try {
      await _servicio.registrarDispositivo();
      final renovacion = _servicio.tokenRenovado.listen((_) => _servicio.registrarDispositivo());
      ref.onDispose(renovacion.cancel);
    } on Object catch (e) {
      // Sin registro no llegan avisos, pero la app sigue funcionando.
      registroApp.w('No se pudo registrar el dispositivo para avisos: $e');
    }
  }

  /// Aviso de prueba a este usuario. Devuelve a cuántos dispositivos se
  /// entregó, o `null` si no se pudo enviar.
  Future<int?> enviarPrueba() async {
    try {
      await _servicio.registrarDispositivo(); // por si el token cambió
      return await _servicio.enviarPrueba();
    } on Object catch (e) {
      registroApp.w('No se pudo enviar el aviso de prueba: $e');
      return null;
    }
  }

  /// Se llama antes de cerrar sesión (aún con el token de acceso vigente).
  Future<void> darDeBaja() async {
    if (state.value != EstadoAvisos.activos) return;
    try {
      await _servicio.darDeBaja().timeout(const Duration(seconds: 5));
    } on Object catch (e) {
      registroApp.w('No se pudo dar de baja el dispositivo: $e');
    }
  }
}

/// Roles que reciben avisos push: Institución ("tu pedido está listo") y
/// Bodega ("nueva entrada/salida por confirmar").
const rolesConAvisos = {RolUsuario.institucion, RolUsuario.bodega};

/// Pantalla que abre un aviso al tocarlo, según su tipo (`null`: ninguna).
String? rutaDeAviso(Map<String, dynamic> datos) {
  switch (datos['tipo']) {
    case 'MOVIMIENTO_PENDIENTE':
      return RutasApp.bodegaPendientes;
    case 'PEDIDO_LISTO':
      final pedidoId = int.tryParse('${datos['pedidoId'] ?? ''}');
      return pedidoId == null ? RutasApp.institucionPedidos : RutasApp.institucionSeguimiento(pedidoId);
    default:
      return null; // aviso de prueba u otro sin pantalla propia
  }
}

/// Atiende los avisos: con la app abierta los muestra (barra del sistema en
/// Android, mensaje en pantalla en web) y refresca los datos afectados; al
/// tocar la notificación abre su pantalla. Se activa desde `AplicacionCostuSoft`.
final proveedorEscuchaAvisos = Provider<void>((ref) {
  if (!ref.watch(proveedorFirebaseDisponible)) return;

  void refrescar(Map<String, dynamic> datos) {
    switch (datos['tipo']) {
      case 'MOVIMIENTO_PENDIENTE':
        ref
          ..invalidate(proveedorMovimientosPendientes)
          ..invalidate(proveedorHistorialMovimientos);
      case 'PEDIDO_LISTO':
        ref
          ..invalidate(proveedorPedidosInstitucion)
          ..invalidate(proveedorPerfilInstitucion);
        if (int.tryParse('${datos['pedidoId'] ?? ''}') case final pedidoId?) {
          ref
            ..invalidate(proveedorPedidoInstitucion(pedidoId))
            ..invalidate(proveedorHistorialInstitucion(pedidoId));
        }
    }
  }

  // `go` y no `push`: si la sesión aún se restaura, el enrutador recuerda
  // la ruta pedida y lleva allí al terminar.
  void abrir(String ruta) => ref.read(proveedorEnrutador).go(ruta);

  void abrirDatos(Map<String, dynamic> datos) {
    refrescar(datos);
    if (rutaDeAviso(datos) case final ruta?) abrir(ruta);
  }

  final enPrimerPlano = FirebaseMessaging.onMessage.listen((mensaje) {
    refrescar(mensaje.data);
    final aviso = mensaje.notification;
    if (aviso == null) return;
    // Android: en la barra del sistema, como con la app cerrada.
    if (CanalAvisos.mostrar(mensaje)) return;
    final ruta = rutaDeAviso(mensaje.data);
    llaveMensajeroApp.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text('${aviso.title ?? 'CostuSoft'}\n${aviso.body ?? ''}'.trim()),
        action: ruta == null ? null : SnackBarAction(label: 'Ver', onPressed: () => abrir(ruta)),
      ),
    );
  });
  final alTocar = FirebaseMessaging.onMessageOpenedApp.listen((m) => abrirDatos(m.data));
  // Aviso mostrado por CanalAvisos (app abierta) que el usuario tocó.
  CanalAvisos.alTocar = abrirDatos;
  ref.onDispose(() {
    unawaited(enPrimerPlano.cancel());
    unawaited(alTocar.cancel());
    CanalAvisos.alTocar = null;
  });

  // La app se abrió tocando un aviso (estaba cerrada).
  unawaited(FirebaseMessaging.instance.getInitialMessage().then((m) => m == null ? null : abrirDatos(m.data)));
  unawaited(CanalAvisos.datosDelAvisoInicial().then((d) => d == null ? null : abrirDatos(d)));
  // Web: clic en el aviso con la app abierta en otra pestaña.
  escucharRutasDelServiceWorker(abrir);
});
