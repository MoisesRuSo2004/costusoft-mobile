import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modulos/autenticacion/dominio/rol_usuario.dart';
import '../../modulos/autenticacion/presentacion/controlador_sesion.dart';
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

/// Solo el rol Institución recibe avisos: "tu pedido está listo".
final proveedorAvisos = AsyncNotifierProvider<ControladorAvisos, EstadoAvisos>(ControladorAvisos.new);

class ControladorAvisos extends AsyncNotifier<EstadoAvisos> {
  ServicioNotificaciones get _servicio => ref.read(proveedorServicioNotificaciones);

  @override
  Future<EstadoAvisos> build() async {
    final rol = ref.watch(proveedorRolActual);
    if (!ref.watch(proveedorFirebaseDisponible) || rol != RolUsuario.institucion) return EstadoAvisos.noDisponible;

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

int? _pedidoDe(RemoteMessage mensaje) => int.tryParse('${mensaje.data['pedidoId'] ?? ''}');

/// Atiende los avisos: con la app abierta muestra un aviso en pantalla y
/// refresca los pedidos; al tocar la notificación abre el seguimiento.
/// Se activa desde `AplicacionCostuSoft`.
final proveedorEscuchaAvisos = Provider<void>((ref) {
  if (!ref.watch(proveedorFirebaseDisponible)) return;

  void refrescar(int? pedidoId) {
    ref
      ..invalidate(proveedorPedidosInstitucion)
      ..invalidate(proveedorPerfilInstitucion);
    if (pedidoId != null) {
      ref
        ..invalidate(proveedorPedidoInstitucion(pedidoId))
        ..invalidate(proveedorHistorialInstitucion(pedidoId));
    }
  }

  // `go` y no `push`: si la sesión aún se restaura, el enrutador recuerda
  // la ruta pedida y lleva allí al terminar.
  void abrir(String ruta) => ref.read(proveedorEnrutador).go(ruta);

  void abrirAviso(RemoteMessage mensaje) {
    final pedidoId = _pedidoDe(mensaje);
    refrescar(pedidoId);
    abrir(pedidoId == null ? RutasApp.institucionPedidos : RutasApp.institucionSeguimiento(pedidoId));
  }

  final enPrimerPlano = FirebaseMessaging.onMessage.listen((mensaje) {
    final pedidoId = _pedidoDe(mensaje);
    refrescar(pedidoId);
    final aviso = mensaje.notification;
    if (aviso == null) return;
    // Android: en la barra del sistema, como con la app cerrada.
    if (CanalAvisos.mostrar(mensaje, pedidoId: pedidoId?.toString())) return;
    llaveMensajeroApp.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text('${aviso.title ?? 'CostuSoft'}\n${aviso.body ?? ''}'.trim()),
        action: pedidoId == null
            ? null
            : SnackBarAction(label: 'Ver', onPressed: () => abrir(RutasApp.institucionSeguimiento(pedidoId))),
      ),
    );
  });
  final alTocar = FirebaseMessaging.onMessageOpenedApp.listen(abrirAviso);
  // Aviso mostrado por CanalAvisos (app abierta) que el usuario tocó.
  void abrirPedido(String? texto) {
    final pedidoId = int.tryParse(texto ?? '');
    refrescar(pedidoId);
    abrir(pedidoId == null ? RutasApp.institucionPedidos : RutasApp.institucionSeguimiento(pedidoId));
  }
  CanalAvisos.alTocar = abrirPedido;
  ref.onDispose(() {
    unawaited(enPrimerPlano.cancel());
    unawaited(alTocar.cancel());
    CanalAvisos.alTocar = null;
  });

  // La app se abrió tocando un aviso (estaba cerrada).
  unawaited(FirebaseMessaging.instance.getInitialMessage().then((m) => m == null ? null : abrirAviso(m)));
  unawaited(CanalAvisos.pedidoDelAvisoInicial().then((p) => p == null ? null : abrirPedido(p)));
  // Web: clic en el aviso con la app abierta en otra pestaña.
  escucharRutasDelServiceWorker(abrir);
});
