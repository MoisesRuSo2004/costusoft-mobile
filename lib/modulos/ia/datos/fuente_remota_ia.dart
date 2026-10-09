import 'package:dio/dio.dart';

import '../../../nucleo/red/cliente_http.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../dominio/entidades_ia.dart';
import 'modelos_ia.dart';

/// El LLM y el solver pueden tardar varios segundos.
final _opcionesLentas = Options(extra: {claveTiempoMaximo: const Duration(seconds: 90)});

/// Llamadas HTTP de `/api/ia`, `/api/optimizacion` y `/api/colegios`.
class FuenteRemotaIa {
  const FuenteRemotaIa(this._cliente, {this.rutaChat = '/api/ia/chat'});

  final Dio _cliente;

  /// El coordinador de un colegio usa `/api/institucion/ia/chat`, que le da
  /// a la IA el contexto de su colegio. Responde con el mismo formato.
  final String rutaChat;

  RespuestaIa _leerRespuesta(Response<Map<String, dynamic>> r, {String campoTexto = 'respuesta'}) =>
      RespuestaApi.desdeJson(
        r.data!,
        (d) => respuestaIaDesdeJson(d! as Map<String, dynamic>, campoTexto: campoTexto),
      ).datos!;

  Future<RespuestaIa> obtenerResumenDelDia() async =>
      _leerRespuesta(await _cliente.get<Map<String, dynamic>>('/api/ia/briefing', options: _opcionesLentas));

  Future<RespuestaIa> consultar(TipoConsultaIa tipo) async => _leerRespuesta(
    await _cliente.post<Map<String, dynamic>>(
      '/api/ia/consultar',
      data: {'tipo': tipo.codigo},
      options: _opcionesLentas,
    ),
  );

  Future<RespuestaIa> preguntar(String pregunta) async => _leerRespuesta(
    await _cliente.post<Map<String, dynamic>>(rutaChat, data: {'pregunta': pregunta}, options: _opcionesLentas),
  );

  Future<RespuestaIa> generarOrdenCompra() async => _leerRespuesta(
    await _cliente.post<Map<String, dynamic>>(
      '/api/ia/orden-compra',
      data: const <String, Object>{},
      options: _opcionesLentas,
    ),
    campoTexto: 'textoOrden',
  );

  Future<List<Colegio>> listarColegios() async {
    final r = await _cliente.get<Map<String, dynamic>>('/api/colegios', queryParameters: {'size': 100});
    final datos = r.data?['data'];
    final lista = datos is Map<String, dynamic> ? datos['content'] as List<dynamic>? : datos as List<dynamic>?;
    return [for (final c in (lista ?? const []).cast<Map<String, dynamic>>()) colegioDesdeJson(c)]
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<PlanProduccion> optimizar({required int colegioId, required bool incluirDemanda}) async {
    final r = await _cliente.post<Map<String, dynamic>>(
      '/api/optimizacion',
      queryParameters: {'colegioId': colegioId, 'incluirDemanda': incluirDemanda},
      options: _opcionesLentas,
    );
    return RespuestaApi.desdeJson(r.data!, (d) => planDesdeRespuesta(d! as Map<String, dynamic>)).datos!;
  }

  Future<List<PlanProduccion>> historial({int limite = 15}) async {
    final r = await _cliente.get<Map<String, dynamic>>(
      '/api/optimizacion/historial',
      queryParameters: {'limit': limite},
    );
    final items = (r.data?['data'] as Map<String, dynamic>?)?['items'] as List<dynamic>? ?? const [];
    return [for (final i in items.cast<Map<String, dynamic>>()) planDesdeHistorial(i)];
  }
}
