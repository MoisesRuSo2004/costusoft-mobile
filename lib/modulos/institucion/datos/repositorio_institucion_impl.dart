import 'package:dio/dio.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/mapeador_errores.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../../pedidos/dominio/pedido.dart';
import '../dominio/perfil_institucion.dart';
import '../dominio/repositorio_institucion.dart';
import 'fuente_remota_institucion.dart';

class RepositorioInstitucionImpl implements RepositorioInstitucion {
  const RepositorioInstitucionImpl(this._fuente);

  final FuenteRemotaInstitucion _fuente;

  Future<Resultado<T>> _proteger<T>(Future<T> Function() llamada) async {
    try {
      return Exito(await llamada());
    } on DioException catch (error) {
      return Falla(mapearErrorDeRed(error));
    } on Object catch (error, pila) {
      registroApp.e('Respuesta inesperada del portal institucional', error: error, stackTrace: pila);
      return const Falla(FalloInesperado('El servidor respondió con datos inesperados.'));
    }
  }

  @override
  Future<Resultado<PerfilInstitucion>> perfil() => _proteger(_fuente.perfil);

  @override
  Future<Resultado<PaginaApi<Pedido>>> listarPedidos({required int pagina, int tamano = 20}) =>
      _proteger(() => _fuente.listarPedidos(pagina: pagina, tamano: tamano));

  @override
  Future<Resultado<Pedido>> obtenerPedido(int id) => _proteger(() => _fuente.obtenerPedido(id));

  @override
  Future<Resultado<List<EventoPedido>>> historial(int id) => _proteger(() => _fuente.historial(id));
}
