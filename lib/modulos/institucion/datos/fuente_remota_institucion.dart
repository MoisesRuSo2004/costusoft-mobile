import 'package:dio/dio.dart';

import '../../../nucleo/red/respuesta_api.dart';
import '../../pedidos/datos/modelos_pedidos.dart';
import '../../pedidos/dominio/pedido.dart';
import '../dominio/perfil_institucion.dart';

/// Llamadas HTTP de `/api/institucion`. Los pedidos llegan con el mismo
/// formato que `/api/pedidos`, así que se reutilizan sus conversores.
class FuenteRemotaInstitucion {
  const FuenteRemotaInstitucion(this._cliente);

  final Dio _cliente;

  Future<PerfilInstitucion> perfil() async {
    final r = await _cliente.get<Map<String, dynamic>>('/api/institucion/perfil');
    return RespuestaApi.desdeJson(r.data!, (d) {
      final json = d! as Map<String, dynamic>;
      return PerfilInstitucion(
        colegioId: (json['colegioId'] as num).toInt(),
        nombreColegio: json['nombreColegio'] as String? ?? 'Mi colegio',
        direccionColegio: json['direccionColegio'] as String?,
        totalPedidos: (json['totalPedidos'] as num?)?.toInt() ?? 0,
        pedidosActivos: (json['pedidosActivos'] as num?)?.toInt() ?? 0,
      );
    }).datos!;
  }

  Future<PaginaApi<Pedido>> listarPedidos({required int pagina, required int tamano}) async {
    final r = await _cliente.get<Map<String, dynamic>>(
      '/api/institucion/pedidos',
      queryParameters: {'page': pagina, 'size': tamano},
    );
    return RespuestaApi.desdeJson(
      r.data!,
      (d) => PaginaApi.desdeJson(d! as Map<String, dynamic>, pedidoDesdeJson),
    ).datos!;
  }

  Future<Pedido> obtenerPedido(int id) async {
    final r = await _cliente.get<Map<String, dynamic>>('/api/institucion/pedidos/$id');
    return RespuestaApi.desdeJson(r.data!, (d) => pedidoDesdeJson(d! as Map<String, dynamic>)).datos!;
  }

  Future<List<EventoPedido>> historial(int id) async {
    final r = await _cliente.get<Map<String, dynamic>>('/api/institucion/pedidos/$id/historial');
    final lista = r.data?['data'] as List<dynamic>? ?? const [];
    return [for (final e in lista.cast<Map<String, dynamic>>()) eventoDesdeJson(e)];
  }
}
