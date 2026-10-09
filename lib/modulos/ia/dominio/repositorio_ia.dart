import '../../../nucleo/errores/resultado.dart';
import 'entidades_ia.dart';

/// Agente de IA (Groq) del backend: `/api/ia`.
abstract interface class RepositorioIa {
  /// Resumen ejecutivo del día.
  Future<Resultado<RespuestaIa>> obtenerResumenDelDia();

  /// Consulta predefinida sobre el inventario.
  Future<Resultado<RespuestaIa>> consultar(TipoConsultaIa tipo);

  /// Pregunta libre (máx. 500 caracteres).
  Future<Resultado<RespuestaIa>> preguntar(String pregunta);

  /// Orden de compra sugerida con los insumos en stock bajo.
  Future<Resultado<RespuestaIa>> generarOrdenCompra();
}

/// Motor de optimización de la producción: `/api/optimizacion`.
abstract interface class RepositorioOptimizacion {
  Future<Resultado<List<Colegio>>> listarColegios();

  /// Calcula y guarda en el historial el plan óptimo para un colegio.
  Future<Resultado<PlanProduccion>> optimizar({required int colegioId, required bool incluirDemanda});

  /// Ejecuciones anteriores, de la más reciente a la más antigua.
  Future<Resultado<List<PlanProduccion>>> historial({int limite = 15});
}
