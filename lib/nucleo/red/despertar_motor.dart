import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errores/fallo.dart';
import '../errores/resultado.dart';

/// Arranque en frío del motor de predicción.
///
/// En producción (Render, plan gratuito) los microservicios se duermen sin
/// uso y tardan 30–60 s en volver. Mientras arrancan el backend responde 503
/// (o la petición vence). En lugar de mostrar el error, se reintenta y la
/// interfaz muestra "Despertando el motor de análisis… N s".

/// Segundos que lleva despertando el motor, o `null` si no está esperando.
final proveedorDespertarMotor = NotifierProvider<ControladorDespertarMotor, int?>(ControladorDespertarMotor.new);

class ControladorDespertarMotor extends Notifier<int?> {
  int _esperas = 0;
  Timer? _reloj;
  DateTime? _inicio;

  @override
  int? build() {
    ref.onDispose(() => _reloj?.cancel());
    return null;
  }

  void _empezar() {
    if (_esperas++ > 0) return; // ya hay otra pantalla esperando al mismo motor
    _inicio = DateTime.now();
    state = 0;
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      state = DateTime.now().difference(_inicio!).inSeconds;
    });
  }

  void _terminar() {
    if (--_esperas > 0) return;
    _reloj?.cancel();
    _reloj = null;
    state = null;
  }
}

/// Fallos que se arreglan esperando a que el motor arranque.
bool esFalloDeArranque(Fallo fallo) => switch (fallo) {
  FalloServicioIniciando() || FalloTiempoAgotado() => true,
  FalloServidor(:final codigoEstado) => codigoEstado == 502 || codigoEstado == 503 || codigoEstado == 504,
  // Backends anteriores respondían 409 cuando el motor no contestaba.
  FalloConflicto() => true,
  _ => false,
};

/// Ejecuta [accion] y, si falla porque el motor está arrancando, reintenta
/// cada [pausa] hasta [limite]. Si se agota, lanza un fallo con un mensaje
/// para el usuario (nunca el detalle técnico del servidor).
Future<T> conMotorDespierto<T>(
  Ref ref,
  Future<Resultado<T>> Function() accion, {
  Duration limite = const Duration(seconds: 120),
  Duration pausa = const Duration(seconds: 5),
}) async {
  final inicio = DateTime.now();
  var esperando = false;
  final despertar = ref.read(proveedorDespertarMotor.notifier);
  try {
    while (true) {
      final resultado = await accion();
      switch (resultado) {
        case Exito(:final datos):
          return datos;
        case Falla(:final fallo) when !esFalloDeArranque(fallo):
          throw fallo;
        case Falla():
          if (DateTime.now().difference(inicio) >= limite) {
            throw const FalloServicioIniciando(
              'El motor de análisis no respondió a tiempo. Intenta de nuevo en un momento.',
            );
          }
          if (!esperando) {
            esperando = true;
            despertar._empezar();
          }
          await Future<void>.delayed(pausa);
          // La pantalla se cerró mientras esperaba: no seguir despertando.
          if (!ref.mounted) throw const FalloInesperado('La consulta se canceló.');
      }
    }
  } finally {
    if (esperando) despertar._terminar();
  }
}
