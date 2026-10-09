import 'package:dio/dio.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/mapeador_errores.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../dominio/movimiento.dart';
import '../dominio/repositorio_movimientos.dart';
import 'modelos_movimientos.dart';

/// Implementación HTTP de [RepositorioMovimientos].
class RepositorioMovimientosImpl implements RepositorioMovimientos {
  const RepositorioMovimientosImpl(this._cliente);

  final Dio _cliente;

  Future<Resultado<T>> _proteger<T>(Future<T> Function() llamada) async {
    try {
      return Exito(await llamada());
    } on DioException catch (error) {
      return Falla(mapearErrorDeRed(error));
    } on Object catch (error, pila) {
      registroApp.e('Respuesta inesperada de movimientos', error: error, stackTrace: pila);
      return const Falla(FalloInesperado('El servidor respondió con datos inesperados.'));
    }
  }

  Movimiento _leer(Response<Map<String, dynamic>> r, TipoMovimiento tipo) =>
      RespuestaApi.desdeJson(r.data!, (d) => movimientoDesdeJson(d! as Map<String, dynamic>, tipo)).datos!;

  @override
  Future<Resultado<PaginaApi<Movimiento>>> listar(
    TipoMovimiento tipo, {
    required int pagina,
    int tamano = 20,
    EstadoMovimiento? estado,
  }) => _proteger(() async {
    // Sin estado: GET /api/{tipo}; con estado: GET /api/{tipo}/estado?estado=…
    final r = await _cliente.get<Map<String, dynamic>>(
      estado == null ? '/api/${tipo.ruta}' : '/api/${tipo.ruta}/estado',
      queryParameters: {'page': pagina, 'size': tamano, 'estado': ?estado?.codigo},
    );
    return RespuestaApi.desdeJson(
      r.data!,
      (d) => PaginaApi.desdeJson(d! as Map<String, dynamic>, (m) => movimientoDesdeJson(m, tipo)),
    ).datos!;
  });

  @override
  Future<Resultado<Movimiento>> obtener(TipoMovimiento tipo, int id) =>
      _proteger(() async => _leer(await _cliente.get<Map<String, dynamic>>('/api/${tipo.ruta}/$id'), tipo));

  @override
  Future<Resultado<Movimiento>> confirmar(TipoMovimiento tipo, int id) =>
      _proteger(() async => _leer(await _cliente.patch<Map<String, dynamic>>('/api/${tipo.ruta}/$id/confirmar'), tipo));

  @override
  Future<Resultado<Movimiento>> rechazar(TipoMovimiento tipo, int id, String motivo) => _proteger(
    () async => _leer(
      await _cliente.patch<Map<String, dynamic>>('/api/${tipo.ruta}/$id/rechazar', data: {'motivo': motivo.trim()}),
      tipo,
    ),
  );
}
