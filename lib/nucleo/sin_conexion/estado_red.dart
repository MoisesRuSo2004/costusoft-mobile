import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errores/resultado.dart';
import '../red/verificador_servidor.dart';
import '../utilidades/registro_app.dart';

/// ¿Se puede hablar con el backend? No basta con tener wifi: el servidor
/// también puede estar caído o inalcanzable.
class EstadoRed {
  const EstadoRed({this.enLinea = true, this.copiaDe});

  final bool enLinea;

  /// Fecha de la copia local más antigua que se está mostrando sin conexión.
  final DateTime? copiaDe;
}

final proveedorRed = NotifierProvider<ControladorRed, EstadoRed>(ControladorRed.new);

/// Lo alimentan tres fuentes: los cambios de red del sistema
/// (`connectivity_plus`), cada respuesta o error de la API (interceptor) y,
/// mientras no hay conexión, una comprobación periódica del servidor.
class ControladorRed extends Notifier<EstadoRed> {
  static const _intervaloComprobacion = Duration(seconds: 15);
  static const _tiempoMaximoComprobacion = Duration(seconds: 8);

  Timer? _temporizador;
  bool _comprobando = false;

  @override
  EstadoRed build() {
    final suscripcion = Connectivity().onConnectivityChanged.listen((redes) {
      if (redes.every((r) => r == ConnectivityResult.none)) {
        marcarSinConexion();
      } else {
        unawaited(comprobar());
      }
    }, onError: (Object error) => registroApp.w('No se pudo observar la red: $error'));
    ref.onDispose(() {
      unawaited(suscripcion.cancel());
      _temporizador?.cancel();
    });
    return const EstadoRed();
  }

  /// El servidor respondió (con cualquier código).
  void marcarEnLinea() {
    _temporizador?.cancel();
    _temporizador = null;
    if (!state.enLinea) state = const EstadoRed();
  }

  void marcarSinConexion() {
    _temporizador ??= Timer.periodic(_intervaloComprobacion, (_) => unawaited(comprobar()));
    if (state.enLinea) state = EstadoRed(enLinea: false, copiaDe: state.copiaDe);
  }

  /// Se mostró una copia local guardada en [guardadaEn].
  void registrarCopia(DateTime guardadaEn) {
    marcarSinConexion();
    final actual = state.copiaDe;
    if (actual == null || guardadaEn.isBefore(actual)) state = EstadoRed(enLinea: false, copiaDe: guardadaEn);
  }

  /// Pregunta al servidor si está disponible y actualiza el estado.
  Future<bool> comprobar() async {
    if (_comprobando) return state.enLinea;
    _comprobando = true;
    try {
      final resultado = await ref.read(proveedorVerificadorServidor).verificar(tiempoMaximo: _tiempoMaximoComprobacion);
      final disponible = resultado is Exito;
      disponible ? marcarEnLinea() : marcarSinConexion();
      return disponible;
    } finally {
      _comprobando = false;
    }
  }
}
