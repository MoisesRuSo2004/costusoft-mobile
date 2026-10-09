import 'package:dio/dio.dart';

import '../../../nucleo/red/respuesta_api.dart';
import '../dominio/pedido.dart';
import 'modelos_pedidos.dart';

/// Llamadas HTTP de `/api/pedidos`.
class FuenteRemotaPedidos {
  const FuenteRemotaPedidos(this._cliente);

  final Dio _cliente;

  Pedido _leerPedido(Response<Map<String, dynamic>> r) =>
      RespuestaApi.desdeJson(r.data!, (d) => pedidoDesdeJson(d! as Map<String, dynamic>)).datos!;

  /// `GET /api/pedidos?page&size&estado&colegioId` (filtro combinado del backend).
  Future<PaginaApi<Pedido>> listar({
    required int pagina,
    required int tamano,
    EstadoPedido? estado,
    int? colegioId,
  }) async {
    final r = await _cliente.get<Map<String, dynamic>>(
      '/api/pedidos',
      queryParameters: {
        'page': pagina,
        'size': tamano,
        if (estado != null) 'estado': estado.codigo,
        'colegioId': ?colegioId,
      },
    );
    return RespuestaApi.desdeJson(
      r.data!,
      (d) => PaginaApi.desdeJson(d! as Map<String, dynamic>, pedidoDesdeJson),
    ).datos!;
  }

  Future<Pedido> obtener(int id) async => _leerPedido(await _cliente.get<Map<String, dynamic>>('/api/pedidos/$id'));

  Future<List<EventoPedido>> historial(int id) async {
    final r = await _cliente.get<Map<String, dynamic>>('/api/pedidos/$id/historial');
    final lista = r.data?['data'] as List<dynamic>? ?? const [];
    return [for (final e in lista.cast<Map<String, dynamic>>()) eventoDesdeJson(e)];
  }

  Future<Pedido> ejecutar(int id, AccionPedido accion) async =>
      _leerPedido(await _cliente.post<Map<String, dynamic>>('/api/pedidos/$id/${accion.ruta}'));

  Future<Pedido> cancelar(int id, String motivo) async =>
      _leerPedido(await _cliente.post<Map<String, dynamic>>('/api/pedidos/$id/cancelar', data: {'motivo': motivo}));
}
