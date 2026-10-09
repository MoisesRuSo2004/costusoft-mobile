import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../../pedidos/dominio/pedido.dart';
import 'perfil_institucion.dart';

/// Portal del colegio: `/api/institucion`. El backend toma el colegio del
/// token, así que el coordinador solo ve los pedidos de su institución.
abstract interface class RepositorioInstitucion {
  Future<Resultado<PerfilInstitucion>> perfil();

  /// Pedidos del colegio, del más reciente al más antiguo.
  Future<Resultado<PaginaApi<Pedido>>> listarPedidos({required int pagina, int tamano = 20});

  Future<Resultado<Pedido>> obtenerPedido(int id);

  Future<Resultado<List<EventoPedido>>> historial(int id);
}
