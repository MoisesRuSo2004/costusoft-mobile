import '../../../nucleo/errores/resultado.dart';
import 'insumo.dart';
import 'prediccion_insumo.dart';

/// Contrato del módulo de inventario.
abstract interface class RepositorioInventario {
  /// Todos los insumos (son pocas decenas: se traen de una vez y se filtran
  /// en el dispositivo, así la búsqueda es instantánea).
  Future<Resultado<List<Insumo>>> listarInsumos();

  Future<Resultado<Insumo>> obtenerInsumo(int id);

  /// Predicción de IA de un insumo (≈1 s).
  Future<Resultado<PrediccionInsumo>> obtenerPrediccion(int insumoId);

  /// Predicción de todos los insumos, ordenada por riesgo. Se carga aparte de
  /// la lista para no retrasarla.
  Future<Resultado<List<PrediccionInsumo>>> obtenerPredicciones();

  /// Corrige el stock tras un conteo físico (solo administrador).
  Future<Resultado<Insumo>> ajustarStock({required int insumoId, required int nuevoStock, String? observacion});
}
