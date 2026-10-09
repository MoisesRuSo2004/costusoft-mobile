/// Par de tokens JWT que emite el backend al iniciar sesión o al renovarla.
class TokensSesion {
  const TokensSesion({required this.acceso, required this.renovacion});

  /// Token de acceso (dura 1 h en producción). Va en `Authorization: Bearer`.
  final String acceso;

  /// Token de renovación (dura 7 días). Sirve para pedir un nuevo par.
  final String renovacion;
}
