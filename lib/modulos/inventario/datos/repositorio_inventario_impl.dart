import 'package:dio/dio.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/mapeador_errores.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';
import '../dominio/repositorio_inventario.dart';
import 'fuente_remota_inventario.dart';

class RepositorioInventarioImpl implements RepositorioInventario {
  const RepositorioInventarioImpl(this._fuenteRemota);

  final FuenteRemotaInventario _fuenteRemota;

  /// Ejecuta una llamada y traduce cualquier error a un [Fallo].
  Future<Resultado<T>> _proteger<T>(Future<T> Function() llamada) async {
    try {
      return Exito(await llamada());
    } on DioException catch (error) {
      return Falla(mapearErrorDeRed(error));
    } on Object catch (error, pila) {
      registroApp.e('Respuesta inesperada del inventario', error: error, stackTrace: pila);
      return const Falla(FalloInesperado('El servidor respondió con datos inesperados.'));
    }
  }

  @override
  Future<Resultado<List<Insumo>>> listarInsumos() => _proteger(_fuenteRemota.listarInsumos);

  @override
  Future<Resultado<Insumo>> obtenerInsumo(int id) => _proteger(() => _fuenteRemota.obtenerInsumo(id));

  @override
  Future<Resultado<PrediccionInsumo>> obtenerPrediccion(int insumoId) =>
      _proteger(() => _fuenteRemota.obtenerPrediccion(insumoId));

  @override
  Future<Resultado<List<PrediccionInsumo>>> obtenerPredicciones() => _proteger(_fuenteRemota.obtenerPredicciones);

  @override
  Future<Resultado<Insumo>> ajustarStock({required int insumoId, required int nuevoStock, String? observacion}) =>
      _proteger(
        () => _fuenteRemota.ajustarStock(insumoId: insumoId, nuevoStock: nuevoStock, observacion: observacion?.trim()),
      );
}
