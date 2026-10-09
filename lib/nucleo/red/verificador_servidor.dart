import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errores/fallo.dart';
import '../errores/resultado.dart';
import 'cliente_http.dart';
import 'mapeador_errores.dart';

/// Verifica que el backend esté disponible.
///
/// El backend no expone un endpoint de salud (actuator), así que se consulta
/// la raíz `/`: Spring Security responde 401, lo que confirma que el servidor
/// está arriba. Cualquier respuesta menor a 500 cuenta como "disponible".
class VerificadorServidor {
  const VerificadorServidor(this._cliente);

  final Dio _cliente;

  /// Devuelve cuánto tardó el servidor en responder.
  /// [tiempoMaximo] acorta la espera en las comprobaciones periódicas.
  Future<Resultado<Duration>> verificar({Duration? tiempoMaximo}) async {
    final cronometro = Stopwatch()..start();
    try {
      final respuesta = await _cliente.get<void>(
        '/',
        options: Options(
          validateStatus: (codigo) => codigo != null && codigo < 500,
          extra: {claveTiempoMaximo: ?tiempoMaximo},
        ),
      );
      return respuesta.statusCode != null ? Exito(cronometro.elapsed) : const Falla(FalloRed());
    } on DioException catch (e) {
      return Falla(mapearErrorDeRed(e));
    } on Object {
      return const Falla(FalloInesperado());
    }
  }
}

final proveedorVerificadorServidor = Provider<VerificadorServidor>(
  (ref) => VerificadorServidor(ref.watch(proveedorClientePublico)),
);
