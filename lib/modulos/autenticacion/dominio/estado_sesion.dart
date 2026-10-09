import 'usuario.dart';

/// Estado de la sesión que consulta el enrutador para decidir a dónde ir.
sealed class EstadoSesion {
  const EstadoSesion();
}

/// Aún no se sabe: la app está verificando el servidor o restaurando la sesión.
final class SesionPendiente extends EstadoSesion {
  const SesionPendiente();
}

/// No hay sesión. [motivo] explica por qué (p. ej. "tu sesión expiró").
final class SinSesion extends EstadoSesion {
  const SinSesion({this.motivo});

  final String? motivo;
}

final class SesionActiva extends EstadoSesion {
  const SesionActiva(this.usuario);

  final Usuario usuario;
}
