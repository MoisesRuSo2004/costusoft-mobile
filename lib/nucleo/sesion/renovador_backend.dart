import 'package:dio/dio.dart';

import 'gestor_tokens.dart';
import 'tokens_sesion.dart';

/// Implementación de [RenovadorTokens] contra `POST /api/auth/refresh`.
///
/// El backend responde 409 (BusinessException) cuando el token de renovación
/// es inválido o venció, y 401 si la cuenta fue desactivada: cualquier
/// respuesta de error del servidor significa que la sesión terminó.
RenovadorTokens renovadorConBackend(Dio clientePublico) => (tokenRenovacion) async {
  try {
    final respuesta = await clientePublico.post<Map<String, dynamic>>(
      '/api/auth/refresh',
      data: {'refreshToken': tokenRenovacion},
    );
    final datos = respuesta.data?['data'] as Map<String, dynamic>?;
    final acceso = datos?['accessToken'] as String?;
    final renovacion = datos?['refreshToken'] as String?;
    if (acceso == null || renovacion == null) throw const RenovacionRechazada();
    return TokensSesion(acceso: acceso, renovacion: renovacion);
  } on DioException catch (error) {
    if (error.type == DioExceptionType.badResponse) throw const RenovacionRechazada();
    rethrow;
  }
};
