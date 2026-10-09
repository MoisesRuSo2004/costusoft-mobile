import 'package:dio/dio.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/mapeador_errores.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../dominio/pedido.dart';
import '../dominio/repositorio_pedidos.dart';
import 'fuente_remota_pedidos.dart';

class RepositorioPedidosImpl implements RepositorioPedidos {
  const RepositorioPedidosImpl(this._fuente);

  final FuenteRemotaPedidos _fuente;

  Future<Resultado<T>> _proteger<T>(Future<T> Function() llamada) async {
    try {
      return Exito(await llamada());
    } on DioException catch (error) {
      return Falla(mapearErrorDeRed(error));
    } on Object catch (error, pila) {
      registroApp.e('Respuesta inesperada de pedidos', error: error, stackTrace: pila);
      return const Falla(FalloInesperado('El servidor respondió con datos inesperados.'));
    }
  }

  @override
  Future<Resultado<PaginaApi<Pedido>>> listar({
    required int pagina,
    int tamano = 20,
    EstadoPedido? estado,
    int? colegioId,
  }) => _proteger(() => _fuente.listar(pagina: pagina, tamano: tamano, estado: estado, colegioId: colegioId));

  @override
  Future<Resultado<Pedido>> obtener(int id) => _proteger(() => _fuente.obtener(id));

  @override
  Future<Resultado<List<EventoPedido>>> historial(int id) => _proteger(() => _fuente.historial(id));

  @override
  Future<Resultado<Pedido>> ejecutar(int id, AccionPedido accion) => _proteger(() => _fuente.ejecutar(id, accion));

  @override
  Future<Resultado<Pedido>> cancelar(int id, String motivo) => _proteger(() => _fuente.cancelar(id, motivo.trim()));
}
