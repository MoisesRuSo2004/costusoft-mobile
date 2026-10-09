import 'package:dio/dio.dart';

import '../sesion/gestor_tokens.dart';

/// Agrega el JWT a cada petición y, si el backend responde 401, renueva la
/// sesión y reintenta la petición original de forma transparente.
///
/// Es un [QueuedInterceptor]: los errores se procesan de uno en uno, así que
/// si diez peticiones reciben 401 a la vez solo la primera renueva el token y
/// las demás reutilizan el nuevo.
class InterceptorAutenticacion extends QueuedInterceptor {
  InterceptorAutenticacion({required this._gestor, required this._clienteReintento});

  final GestorTokens _gestor;

  /// Cliente sin este interceptor, para reintentar sin volver a encolar.
  final Dio _clienteReintento;

  /// Rutas que no llevan token y cuyo 401 significa "credenciales inválidas",
  /// no "sesión vencida".
  static const _rutasPublicas = ['/api/auth/login', '/api/auth/refresh', '/api/seguridad/'];

  static const _marcaReintento = 'reintentado';

  bool _esPublica(RequestOptions opciones) => _rutasPublicas.any(opciones.path.startsWith);

  @override
  Future<void> onRequest(RequestOptions opciones, RequestInterceptorHandler manejador) async {
    if (!_esPublica(opciones)) {
      final token = await _gestor.tokenAccesoVigente();
      if (token != null) opciones.headers['Authorization'] = 'Bearer $token';
    }
    manejador.next(opciones);
  }

  @override
  Future<void> onError(DioException error, ErrorInterceptorHandler manejador) async {
    final opciones = error.requestOptions;
    final debeRenovar =
        error.response?.statusCode == 401 && !_esPublica(opciones) && opciones.extra[_marcaReintento] != true;
    if (!debeRenovar) {
      manejador.next(error);
      return;
    }

    // Si otra petición ya renovó mientras esta esperaba en la cola,
    // se usa ese token en lugar de renovar de nuevo.
    final tokenUsado = (opciones.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');
    final tokenActual = _gestor.tokenAcceso;
    final tokenNuevo = (tokenActual != null && tokenActual != tokenUsado) ? tokenActual : await _gestor.renovar();

    if (tokenNuevo == null) {
      manejador.next(error);
      return;
    }

    try {
      opciones.headers['Authorization'] = 'Bearer $tokenNuevo';
      opciones.extra[_marcaReintento] = true;
      manejador.resolve(await _clienteReintento.fetch<dynamic>(opciones));
    } on DioException catch (errorReintento) {
      manejador.next(errorReintento);
    }
  }
}
