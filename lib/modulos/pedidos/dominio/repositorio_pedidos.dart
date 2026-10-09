import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/respuesta_api.dart';
import 'pedido.dart';

/// Pedidos de uniformes: `/api/pedidos`.
abstract interface class RepositorioPedidos {
  /// Página de pedidos, del más reciente al más antiguo. Los filtros son
  /// opcionales y se aplican en el servidor (hay miles de pedidos).
  Future<Resultado<PaginaApi<Pedido>>> listar({
    required int pagina,
    int tamano = 20,
    EstadoPedido? estado,
    int? colegioId,
  });

  Future<Resultado<Pedido>> obtener(int id);

  /// Cambios de estado registrados, del más reciente al más antiguo.
  Future<Resultado<List<EventoPedido>>> historial(int id);

  /// Avanza el pedido al siguiente estado.
  Future<Resultado<Pedido>> ejecutar(int id, AccionPedido accion);

  Future<Resultado<Pedido>> cancelar(int id, String motivo);
}
