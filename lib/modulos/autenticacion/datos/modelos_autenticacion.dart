import '../dominio/rol_usuario.dart';
import '../dominio/usuario.dart';

/// Espejo de `AuthResponseDTO.UsuarioInfoDTO` del backend.
class UsuarioDto {
  const UsuarioDto({required this.id, required this.username, required this.correo, required this.rol, this.fotoUrl});

  factory UsuarioDto.desdeJson(Map<String, dynamic> json) => UsuarioDto(
    id: (json['id'] as num?)?.toInt() ?? 0,
    username: json['username'] as String? ?? '',
    correo: json['correo'] as String? ?? '',
    rol: json['rol'] as String? ?? '',
    fotoUrl: json['fotoUrl'] as String?,
  );

  final int id;
  final String username;
  final String correo;
  final String rol;
  final String? fotoUrl;

  Usuario aEntidad() => Usuario(
    id: id,
    nombreUsuario: username,
    correo: correo,
    rol: RolUsuario.desdeCodigo(rol),
    fotoUrl: (fotoUrl?.isEmpty ?? true) ? null : fotoUrl,
  );
}

/// Espejo de `AuthResponseDTO`: `{ accessToken, refreshToken, tokenType, expiresIn, usuario }`.
class RespuestaAutenticacionDto {
  const RespuestaAutenticacionDto({required this.tokenAcceso, required this.tokenRenovacion, required this.usuario});

  factory RespuestaAutenticacionDto.desdeJson(Map<String, dynamic> json) => RespuestaAutenticacionDto(
    tokenAcceso: json['accessToken'] as String,
    tokenRenovacion: json['refreshToken'] as String,
    usuario: UsuarioDto.desdeJson(json['usuario'] as Map<String, dynamic>),
  );

  final String tokenAcceso;
  final String tokenRenovacion;
  final UsuarioDto usuario;
}
