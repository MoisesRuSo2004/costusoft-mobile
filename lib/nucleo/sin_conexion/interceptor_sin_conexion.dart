import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../utilidades/registro_app.dart';
import 'copia_local.dart';

/// Clave de `Options.extra` para que una consulta no se guarde ni se sirva
/// desde la copia local (p. ej. el envío de la bandeja de salida).
const claveSinCopia = 'sinCopia';

/// Clave de `Response.extra` que indica que la respuesta salió de la copia.
const claveDesdeCopia = 'desdeCopia';

/// Hace que la app funcione sin conexión sin cambiar cada repositorio:
///
/// - Cada respuesta GET con JSON se guarda en la [CopiaLocal].
/// - Si el servidor no se alcanza, la consulta se responde con la última
///   copia guardada y se avisa para que la interfaz lo indique.
/// - Informa si el servidor respondió o no, para el estado de la red.
///
/// Va al final de la cadena de interceptores: los errores 401 ya los resolvió
/// el de autenticación.
class InterceptorSinConexion extends Interceptor {
  InterceptorSinConexion({
    required this._copia,
    required this._alResponderServidor,
    required this._alPerderConexion,
    required this._alUsarCopia,
  });

  final CopiaLocal _copia;
  final void Function() _alResponderServidor;
  final void Function() _alPerderConexion;
  final void Function(DateTime guardadaEn) _alUsarCopia;

  static String claveDe(RequestOptions opciones) => '${opciones.method} ${opciones.uri}';

  bool _esCopiable(RequestOptions opciones) =>
      opciones.method == 'GET' && opciones.extra[claveSinCopia] != true && opciones.responseType == ResponseType.json;

  @override
  void onResponse(Response<dynamic> respuesta, ResponseInterceptorHandler manejador) {
    _alResponderServidor();
    final datos = respuesta.data;
    if (_esCopiable(respuesta.requestOptions) && respuesta.statusCode == 200 && (datos is Map || datos is List)) {
      unawaited(
        _copia
            .guardar(claveDe(respuesta.requestOptions), jsonEncode(datos))
            .catchError((Object e) => registroApp.w('No se pudo guardar la copia local: $e')),
      );
    }
    manejador.next(respuesta);
  }

  @override
  Future<void> onError(DioException error, ErrorInterceptorHandler manejador) async {
    if (error.response != null) {
      _alResponderServidor(); // El servidor contestó, aunque fuera con un error.
      manejador.next(error);
      return;
    }
    // Sin respuesta: sin red, servidor caído o demasiado lento.
    if (error.type == DioExceptionType.connectionError) _alPerderConexion();

    final opciones = error.requestOptions;
    if (!_esCopiable(opciones)) {
      manejador.next(error);
      return;
    }
    RespuestaGuardada? guardada;
    try {
      guardada = await _copia.leer(claveDe(opciones));
    } on Object catch (e) {
      registroApp.w('No se pudo leer la copia local: $e');
    }
    if (guardada == null) {
      manejador.next(error);
      return;
    }
    _alUsarCopia(guardada.guardadaEn);
    manejador.resolve(
      Response<dynamic>(
        requestOptions: opciones,
        data: jsonDecode(guardada.cuerpo),
        statusCode: 200,
        extra: {claveDesdeCopia: true},
      ),
    );
  }
}
