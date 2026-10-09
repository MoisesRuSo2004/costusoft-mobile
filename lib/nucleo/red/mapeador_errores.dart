import 'package:dio/dio.dart';

import '../errores/fallo.dart';

/// Traduce cualquier error de red a un [Fallo] del dominio.
Fallo mapearErrorDeRed(Object error) {
  if (error is! DioException) return const FalloInesperado();

  switch (error.type) {
    case DioExceptionType.connectionError:
      // La conexión ni siquiera se abrió: la petición no llegó al servidor.
      return const FalloRed.sinEnviar();
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.unknown:
      // En web el límite de conexión cubre también la espera de la respuesta:
      // la petición pudo haber llegado.
      return const FalloRed();
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const FalloTiempoAgotado();
    case DioExceptionType.badCertificate:
      return const FalloRed('Conexión no segura con el servidor.');
    case DioExceptionType.cancel:
      return const FalloInesperado('La solicitud fue cancelada.');
    case DioExceptionType.badResponse:
      return _falloDesdeRespuesta(error.response);
  }
}

Fallo _falloDesdeRespuesta(Response<dynamic>? respuesta) {
  final codigo = respuesta?.statusCode ?? 0;
  final mensajeBackend = _mensajeDelBackend(respuesta?.data);

  return switch (codigo) {
    400 || 422 => FalloValidacion(
      mensajeBackend ?? 'Los datos enviados no son válidos.',
      erroresPorCampo: _erroresPorCampo(respuesta?.data),
    ),
    401 => mensajeBackend != null ? FalloNoAutorizado(mensajeBackend) : const FalloNoAutorizado(),
    403 => mensajeBackend != null ? FalloPermiso(mensajeBackend) : const FalloPermiso(),
    404 => mensajeBackend != null ? FalloNoEncontrado(mensajeBackend) : const FalloNoEncontrado(),
    409 => FalloConflicto(mensajeBackend ?? 'Conflicto con el estado actual.'),
    >= 500 => FalloServidor(mensajeBackend ?? 'Ocurrió un error en el servidor. Intenta más tarde.', codigo),
    _ => FalloServidor(mensajeBackend ?? 'Respuesta inesperada ($codigo).', codigo),
  };
}

/// El backend responde los errores como `ApiResponse.error(message, data)`.
String? _mensajeDelBackend(Object? datos) {
  if (datos is Map<String, dynamic>) {
    final mensaje = datos['message'];
    if (mensaje is String && mensaje.trim().isNotEmpty) return mensaje;
  }
  return null;
}

/// Errores de validación por campo, si el backend los envía en `data`.
Map<String, String> _erroresPorCampo(Object? datos) {
  if (datos is Map<String, dynamic>) {
    final campos = datos['data'];
    if (campos is Map<String, dynamic>) {
      return campos.map((campo, error) => MapEntry(campo, error.toString()));
    }
  }
  return const {};
}
