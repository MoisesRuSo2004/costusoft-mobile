import '../../../nucleo/errores/resultado.dart';
import 'usuario.dart';

/// Contrato de autenticación. La capa de presentación solo conoce esto;
/// la implementación vive en `datos/`.
abstract interface class RepositorioAutenticacion {
  /// Inicia sesión con las mismas credenciales de la plataforma web.
  Future<Resultado<Usuario>> iniciarSesion({required String nombreUsuario, required String clave});

  /// Recupera la sesión guardada al abrir la app.
  /// `Exito(null)` significa que no hay sesión (o que ya no es válida).
  Future<Resultado<Usuario?>> restaurarSesion();

  Future<void> cerrarSesion();

  /// Pide al backend que envíe al correo un enlace para restablecer la
  /// contraseña. Devuelve el mensaje del servidor para mostrarlo.
  Future<Resultado<String>> solicitarRecuperacionClave(String correo);

  /// Emite cuando la sesión vence y no se puede renovar.
  Stream<void> get sesionExpirada;
}
