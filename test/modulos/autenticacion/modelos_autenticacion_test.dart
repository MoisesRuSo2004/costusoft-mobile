import 'package:costusoft_mobile/modulos/autenticacion/datos/modelos_autenticacion.dart';
import 'package:costusoft_mobile/modulos/autenticacion/dominio/rol_usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee la respuesta de POST /api/auth/login', () {
    final respuesta = RespuestaAutenticacionDto.desdeJson({
      'accessToken': 'acceso',
      'refreshToken': 'renovacion',
      'tokenType': 'Bearer',
      'expiresIn': 3600000,
      'usuario': {'id': 7, 'username': 'bodega.central', 'correo': 'b@costusoft.com', 'rol': 'BODEGA', 'fotoUrl': ''},
    });

    final usuario = respuesta.usuario.aEntidad();
    expect(respuesta.tokenAcceso, 'acceso');
    expect(respuesta.tokenRenovacion, 'renovacion');
    expect(usuario.id, 7);
    expect(usuario.rol, RolUsuario.bodega);
    expect(usuario.fotoUrl, isNull, reason: 'una URL vacía se trata como "sin foto"');
    expect(usuario.iniciales, 'BC');
  });

  test('un rol desconocido se trata como Usuario (mínimos permisos)', () {
    expect(RolUsuario.desdeCodigo('SUPERADMIN'), RolUsuario.usuario);
    expect(RolUsuario.desdeCodigo('admin'), RolUsuario.administrador);
  });
}
