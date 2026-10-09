/// Fallos del dominio. La interfaz nunca recibe excepciones de Dio ni de la
/// plataforma: los repositorios las traducen a uno de estos tipos.
sealed class Fallo {
  const Fallo(this.mensaje);

  final String mensaje;

  @override
  String toString() => '$runtimeType($mensaje)';
}

/// Sin red, tiempo de conexión agotado o servidor inalcanzable.
final class FalloRed extends Fallo {
  const FalloRed([super.mensaje = 'No hay conexión con el servidor. Revisa tu red.']) : noSeEnvio = false;

  /// La petición no salió del dispositivo (sin red o servidor caído): se
  /// puede reenviar más tarde sin riesgo de aplicarla dos veces.
  const FalloRed.sinEnviar([super.mensaje = 'No hay conexión con el servidor. Revisa tu red.']) : noSeEnvio = true;

  final bool noSeEnvio;
}

/// El servidor tardó demasiado en responder (p. ej. arranque en frío de Render).
final class FalloTiempoAgotado extends Fallo {
  const FalloTiempoAgotado([super.mensaje = 'El servidor está tardando en responder. Intenta de nuevo.']);
}

/// 400 — datos inválidos. El mensaje viene de la RespuestaApi del backend.
final class FalloValidacion extends Fallo {
  const FalloValidacion(super.mensaje, {this.erroresPorCampo = const {}});

  final Map<String, String> erroresPorCampo;
}

/// 401 sin posibilidad de renovar la sesión.
final class FalloNoAutorizado extends Fallo {
  const FalloNoAutorizado([super.mensaje = 'Tu sesión expiró. Inicia sesión de nuevo.']);
}

/// 403 — el rol no tiene permiso.
final class FalloPermiso extends Fallo {
  const FalloPermiso([super.mensaje = 'No tienes permiso para realizar esta acción.']);
}

final class FalloNoEncontrado extends Fallo {
  const FalloNoEncontrado([super.mensaje = 'El recurso no existe.']);
}

final class FalloConflicto extends Fallo {
  const FalloConflicto(super.mensaje);
}

/// 5xx o respuesta inesperada del servidor.
final class FalloServidor extends Fallo {
  const FalloServidor([super.mensaje = 'Ocurrió un error en el servidor. Intenta más tarde.', this.codigoEstado]);

  final int? codigoEstado;
}

final class FalloInesperado extends Fallo {
  const FalloInesperado([super.mensaje = 'Ocurrió un error inesperado.']);
}
