import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errores/fallo.dart';
import '../red/cliente_http.dart';
import '../red/mapeador_errores.dart';
import '../utilidades/registro_app.dart';
import 'almacen_local.dart';
import 'bandeja_salida.dart';
import 'estado_red.dart';
import 'interceptor_sin_conexion.dart';

/// Resultado de una pasada por la bandeja de salida.
class ResumenSincronizacion {
  const ResumenSincronizacion({this.aplicadas = const [], this.conflictos = 0, this.interrumpida = false});

  final List<AccionPendiente> aplicadas;
  final int conflictos;

  /// Se detuvo por falta de conexión o un error pasajero del servidor.
  final bool interrumpida;
}

/// Envía la bandeja de salida en orden (FIFO).
///
/// - Éxito: la acción sale de la bandeja.
/// - El servidor la rechaza (4xx, p. ej. el movimiento ya fue confirmado por
///   otra persona): queda como conflicto para que el usuario la revise, y se
///   sigue con la siguiente.
/// - Sin conexión o error 5xx: se detiene y se reintenta más tarde, sin
///   saltarse el orden.
class Sincronizador {
  const Sincronizador({required this._bandeja, required this._enviar});

  final BandejaSalida _bandeja;
  final Future<void> Function(SolicitudPendiente solicitud) _enviar;

  Future<ResumenSincronizacion> sincronizar() async {
    final aplicadas = <AccionPendiente>[];
    var conflictos = 0;
    for (final accion in await _bandeja.listarPendientes()) {
      try {
        await _enviar(accion.solicitud);
        await _bandeja.eliminar(accion.id);
        aplicadas.add(accion);
      } on DioException catch (error) {
        final fallo = mapearErrorDeRed(error);
        final esPasajero = error.response == null || fallo is FalloServidor || fallo is FalloNoAutorizado;
        if (esPasajero) {
          await _bandeja.registrarIntento(accion.id, fallo.mensaje);
          return ResumenSincronizacion(aplicadas: aplicadas, conflictos: conflictos, interrumpida: true);
        }
        await _bandeja.marcarConflicto(accion.id, fallo.mensaje);
        conflictos++;
      }
    }
    return ResumenSincronizacion(aplicadas: aplicadas, conflictos: conflictos);
  }
}

class EstadoSincronizacion {
  const EstadoSincronizacion({this.acciones = const [], this.enviando = false});

  final List<AccionPendiente> acciones;
  final bool enviando;

  int get pendientes => acciones.where((a) => a.estado == EstadoAccion.pendiente).length;

  int get conflictos => acciones.where((a) => a.estado == EstadoAccion.conflicto).length;

  /// Recursos con un cambio esperando envío (la interfaz no deja repetirlo).
  Set<String> get recursosEnCola => {
    for (final a in acciones)
      if (a.estado == EstadoAccion.pendiente) a.solicitud.recurso,
  };
}

final proveedorSincronizacion = NotifierProvider<ControladorSincronizacion, EstadoSincronizacion>(
  ControladorSincronizacion.new,
);

/// Mantiene la bandeja a la vista de la interfaz y la envía al recuperar la
/// conexión, cada 30 s si quedan pendientes, o cuando el usuario lo pide.
class ControladorSincronizacion extends Notifier<EstadoSincronizacion> {
  static const _intervalo = Duration(seconds: 30);

  final _aplicadas = StreamController<List<AccionPendiente>>.broadcast();

  /// Acciones que el servidor aceptó en cada pasada, para refrescar las pantallas.
  Stream<List<AccionPendiente>> get aplicadas => _aplicadas.stream;

  @override
  EstadoSincronizacion build() {
    final bandeja = ref.watch(proveedorBandejaSalida);
    var primeraLectura = true;
    final suscripcion = bandeja.observar().listen((acciones) {
      state = EstadoSincronizacion(acciones: acciones, enviando: state.enviando);
      if (primeraLectura) {
        primeraLectura = false;
        unawaited(sincronizar()); // Lo que quedó en cola de una sesión anterior.
      }
    }, onError: (Object e) => registroApp.w('No se pudo leer la bandeja de salida: $e'));
    ref.listen(proveedorRed, (anterior, actual) {
      if (anterior?.enLinea == false && actual.enLinea) unawaited(sincronizar());
    });
    final temporizador = Timer.periodic(_intervalo, (_) {
      if (state.pendientes > 0) unawaited(sincronizar());
    });
    ref.onDispose(() {
      unawaited(suscripcion.cancel());
      temporizador.cancel();
      unawaited(_aplicadas.close());
    });
    return const EstadoSincronizacion();
  }

  Future<void> sincronizar() async {
    if (state.enviando || state.pendientes == 0 || !ref.read(proveedorRed).enLinea) return;
    state = EstadoSincronizacion(acciones: state.acciones, enviando: true);
    try {
      final cliente = ref.read(proveedorClienteHttp);
      final resumen = await Sincronizador(
        bandeja: ref.read(proveedorBandejaSalida),
        enviar: (s) => cliente.request<dynamic>(
          s.ruta,
          data: s.cuerpo,
          options: Options(method: s.metodo, extra: {claveSinCopia: true}),
        ),
      ).sincronizar();
      if (resumen.aplicadas.isNotEmpty) _aplicadas.add(resumen.aplicadas);
      if (resumen.aplicadas.isNotEmpty || resumen.conflictos > 0) {
        registroApp.i(
          'Bandeja de salida: ${resumen.aplicadas.length} enviadas, ${resumen.conflictos} en conflicto'
          '${resumen.interrumpida ? ' (interrumpida)' : ''}',
        );
      }
    } finally {
      state = EstadoSincronizacion(acciones: state.acciones);
    }
  }

  /// Quita una acción de la bandeja sin enviarla.
  Future<void> descartar(int id) => ref.read(proveedorBandejaSalida).eliminar(id);
}

/// Emite las acciones aplicadas en cada pasada de sincronización.
final proveedorAccionesAplicadas = StreamProvider<List<AccionPendiente>>(
  (ref) => ref.watch(proveedorSincronizacion.notifier).aplicadas,
);
