import 'package:dio/dio.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/mapeador_errores.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../dominio/repositorio_tablero.dart';
import '../dominio/resumen_tablero.dart';
import 'fuente_remota_tablero.dart';

class RepositorioTableroImpl implements RepositorioTablero {
  const RepositorioTableroImpl(this._fuente);

  final FuenteRemotaTablero _fuente;

  Future<Resultado<T>> _proteger<T>(Future<T> Function() llamada) async {
    try {
      return Exito(await llamada());
    } on DioException catch (error) {
      return Falla(mapearErrorDeRed(error));
    } on Object catch (error, pila) {
      registroApp.e('Respuesta inesperada del tablero', error: error, stackTrace: pila);
      return const Falla(FalloInesperado('El servidor respondió con datos inesperados.'));
    }
  }

  @override
  Future<Resultado<ResumenTablero>> obtenerResumen() => _proteger(_fuente.obtenerResumen);

  @override
  Future<Resultado<ConteoPedidos>> contarPedidos() => _proteger(_fuente.contarPedidos);
}
