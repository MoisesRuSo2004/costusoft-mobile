import 'package:dio/dio.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/mapeador_errores.dart';
import '../../../nucleo/sesion/gestor_tokens.dart';
import '../../../nucleo/sesion/tokens_sesion.dart';
import '../../../nucleo/utilidades/registro_app.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario.dart';
import 'fuente_remota_autenticacion.dart';

class RepositorioAutenticacionImpl implements RepositorioAutenticacion {
  const RepositorioAutenticacionImpl({required this._fuenteRemota, required this._gestorTokens});

  final FuenteRemotaAutenticacion _fuenteRemota;
  final GestorTokens _gestorTokens;

  @override
  Stream<void> get sesionExpirada => _gestorTokens.sesionExpirada;

  @override
  Future<Resultado<Usuario>> iniciarSesion({required String nombreUsuario, required String clave}) async {
    try {
      final respuesta = await _fuenteRemota.iniciarSesion(nombreUsuario: nombreUsuario.trim(), clave: clave);
      await _gestorTokens.guardar(TokensSesion(acceso: respuesta.tokenAcceso, renovacion: respuesta.tokenRenovacion));
      return Exito(respuesta.usuario.aEntidad());
    } on DioException catch (error) {
      return Falla(mapearErrorDeRed(error));
    } on Object catch (error, pila) {
      registroApp.e('Respuesta de login inesperada', error: error, stackTrace: pila);
      return const Falla(FalloInesperado('El servidor respondió algo inesperado al iniciar sesión.'));
    }
  }

  @override
  Future<Resultado<Usuario?>> restaurarSesion() async {
    await _gestorTokens.cargar();
    if (!_gestorTokens.tieneSesion) return const Exito(null);

    try {
      // Si el token venció, el interceptor lo renueva antes de esta llamada.
      final usuario = await _fuenteRemota.obtenerUsuarioActual();
      return Exito(usuario.aEntidad());
    } on DioException catch (error) {
      final fallo = mapearErrorDeRed(error);
      // Sesión inválida en el servidor: se descarta y se pide iniciar sesión.
      if (fallo is FalloNoAutorizado || fallo is FalloConflicto || fallo is FalloServidor) {
        await _gestorTokens.limpiar();
        return const Exito(null);
      }
      return Falla(fallo); // Problema de red: se puede reintentar.
    }
  }

  @override
  Future<void> cerrarSesion() => _gestorTokens.limpiar();

  @override
  Future<Resultado<String>> solicitarRecuperacionClave(String correo) async {
    try {
      return Exito(await _fuenteRemota.solicitarRecuperacionClave(correo.trim()));
    } on DioException catch (error) {
      return Falla(mapearErrorDeRed(error));
    }
  }
}
