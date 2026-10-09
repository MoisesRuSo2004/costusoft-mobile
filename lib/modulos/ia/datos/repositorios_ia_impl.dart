import 'package:dio/dio.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/mapeador_errores.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../dominio/entidades_ia.dart';
import '../dominio/repositorio_ia.dart';
import 'fuente_remota_ia.dart';

Future<Resultado<T>> _proteger<T>(Future<T> Function() llamada) async {
  try {
    return Exito(await llamada());
  } on DioException catch (error) {
    return Falla(mapearErrorDeRed(error));
  } on Object catch (error, pila) {
    registroApp.e('Respuesta inesperada del módulo IA', error: error, stackTrace: pila);
    return const Falla(FalloInesperado('El servidor respondió con datos inesperados.'));
  }
}

/// Si la IA responde vacío, se trata como fallo para que la interfaz lo muestre.
Future<Resultado<RespuestaIa>> _respuestaNoVacia(Future<RespuestaIa> Function() llamada) async {
  final resultado = await _proteger(llamada);
  if (resultado case Exito(:final datos) when datos.texto.isEmpty) {
    return const Falla(FalloServidor('La IA no generó una respuesta. Intenta de nuevo.'));
  }
  return resultado;
}

class RepositorioIaImpl implements RepositorioIa {
  const RepositorioIaImpl(this._fuente);

  final FuenteRemotaIa _fuente;

  @override
  Future<Resultado<RespuestaIa>> obtenerResumenDelDia() => _respuestaNoVacia(_fuente.obtenerResumenDelDia);

  @override
  Future<Resultado<RespuestaIa>> consultar(TipoConsultaIa tipo) => _respuestaNoVacia(() => _fuente.consultar(tipo));

  @override
  Future<Resultado<RespuestaIa>> preguntar(String pregunta) =>
      _respuestaNoVacia(() => _fuente.preguntar(pregunta.trim()));

  @override
  Future<Resultado<RespuestaIa>> generarOrdenCompra() => _respuestaNoVacia(_fuente.generarOrdenCompra);
}

class RepositorioOptimizacionImpl implements RepositorioOptimizacion {
  const RepositorioOptimizacionImpl(this._fuente);

  final FuenteRemotaIa _fuente;

  @override
  Future<Resultado<List<Colegio>>> listarColegios() => _proteger(_fuente.listarColegios);

  @override
  Future<Resultado<PlanProduccion>> optimizar({required int colegioId, required bool incluirDemanda}) =>
      _proteger(() => _fuente.optimizar(colegioId: colegioId, incluirDemanda: incluirDemanda));

  @override
  Future<Resultado<List<PlanProduccion>>> historial({int limite = 15}) =>
      _proteger(() => _fuente.historial(limite: limite));
}
