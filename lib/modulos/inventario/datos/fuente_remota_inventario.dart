import 'package:dio/dio.dart';

import '../../../nucleo/red/cliente_http.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';
import 'modelos_inventario.dart';

/// Llamadas HTTP de `/api/insumos` y `/api/prediccion`.
class FuenteRemotaInventario {
  const FuenteRemotaInventario(this._cliente);

  final Dio _cliente;

  /// Tamaño de página: el máximo que acepta el backend.
  static const _tamanoPagina = 100;

  /// Trae el catálogo completo de insumos (se filtra en el dispositivo y, en
  /// la Fase 6, se guarda para el modo sin conexión).
  ///
  /// Pide la primera página para conocer el total y luego las demás **en
  /// paralelo**: con 1.000 insumos son 10 páginas que llegan casi a la vez,
  /// en lugar de esperarlas una tras otra.
  Future<List<Insumo>> listarInsumos() async {
    final primera = await _pagina(0);
    if (!primera.hayMasPaginas) return primera.contenido;
    final resto = await Future.wait([for (var p = 1; p < primera.totalPaginas; p++) _pagina(p)]);
    return [...primera.contenido, for (final pagina in resto) ...pagina.contenido];
  }

  Future<PaginaApi<Insumo>> _pagina(int numero) async {
    final respuesta = await _cliente.get<Map<String, dynamic>>(
      '/api/insumos',
      queryParameters: {'page': numero, 'size': _tamanoPagina, 'sortBy': 'nombre', 'sortDir': 'asc'},
    );
    return RespuestaApi.desdeJson(
      respuesta.data!,
      (datos) => PaginaApi.desdeJson(datos! as Map<String, dynamic>, insumoDesdeJson),
    ).datos!;
  }

  Future<Insumo> obtenerInsumo(int id) async {
    final respuesta = await _cliente.get<Map<String, dynamic>>('/api/insumos/$id');
    return RespuestaApi.desdeJson(respuesta.data!, (datos) => insumoDesdeJson(datos! as Map<String, dynamic>)).datos!;
  }

  Future<PrediccionInsumo> obtenerPrediccion(int insumoId) async {
    final respuesta = await _cliente.get<Map<String, dynamic>>('/api/prediccion/$insumoId');
    return RespuestaApi.desdeJson(
      respuesta.data!,
      (datos) => prediccionDesdeJson(datos! as Map<String, dynamic>),
    ).datos!;
  }

  /// Predicción de todos los insumos, ordenada por riesgo (crítico primero).
  /// El microservicio la sirve desde caché (≈0,1 s); el tiempo amplio cubre
  /// el caso en que aún no la ha calculado tras arrancar.
  Future<List<PrediccionInsumo>> obtenerPredicciones() async {
    final respuesta = await _cliente.get<Map<String, dynamic>>(
      '/api/prediccion/todos',
      // Evalúa todos los insumos en el microservicio: puede tardar.
      options: Options(extra: {claveTiempoMaximo: const Duration(seconds: 90)}),
    );
    final datos = respuesta.data?['data'] as Map<String, dynamic>? ?? const {};
    final predicciones = datos['predicciones'] as List<dynamic>? ?? const [];
    return [for (final p in predicciones.cast<Map<String, dynamic>>()) prediccionDesdeJson(p)];
  }

  /// `PATCH /api/insumos/{id}/stock` — solo ADMIN.
  Future<Insumo> ajustarStock({required int insumoId, required int nuevoStock, String? observacion}) async {
    final respuesta = await _cliente.patch<Map<String, dynamic>>(
      '/api/insumos/$insumoId/stock',
      data: {'nuevoStock': nuevoStock, if (observacion != null && observacion.isNotEmpty) 'observacion': observacion},
    );
    return RespuestaApi.desdeJson(respuesta.data!, (datos) => insumoDesdeJson(datos! as Map<String, dynamic>)).datos!;
  }
}
