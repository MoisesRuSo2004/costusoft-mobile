import 'package:dio/dio.dart';

import '../../../nucleo/red/respuesta_api.dart';
import 'modelos_autenticacion.dart';

/// Llamadas HTTP del módulo `/api/auth` del backend.
class FuenteRemotaAutenticacion {
  const FuenteRemotaAutenticacion({required this._clientePublico, required this._clienteAutenticado});

  final Dio _clientePublico;
  final Dio _clienteAutenticado;

  /// `POST /api/auth/login`
  Future<RespuestaAutenticacionDto> iniciarSesion({required String nombreUsuario, required String clave}) async {
    final respuesta = await _clientePublico.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'username': nombreUsuario, 'password': clave},
    );
    return RespuestaApi.desdeJson(
      respuesta.data!,
      (datos) => RespuestaAutenticacionDto.desdeJson(datos! as Map<String, dynamic>),
    ).datos!;
  }

  /// `POST /api/seguridad/forgot-password` — el backend siempre responde el
  /// mismo mensaje, exista o no el correo (para no revelar cuentas).
  Future<String> solicitarRecuperacionClave(String correo) async {
    final respuesta = await _clientePublico.post<Map<String, dynamic>>(
      '/api/seguridad/forgot-password',
      data: {'correo': correo},
    );
    return RespuestaApi.desdeJson(respuesta.data!, (_) => null).mensaje;
  }

  /// `GET /api/auth/me` — datos del dueño del token.
  Future<UsuarioDto> obtenerUsuarioActual() async {
    final respuesta = await _clienteAutenticado.get<Map<String, dynamic>>('/api/auth/me');
    return RespuestaApi.desdeJson(
      respuesta.data!,
      (datos) => UsuarioDto.desdeJson(datos! as Map<String, dynamic>),
    ).datos!;
  }
}
