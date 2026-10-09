/// Colegio del coordinador y sus totales (`GET /api/institucion/perfil`).
class PerfilInstitucion {
  const PerfilInstitucion({
    required this.colegioId,
    required this.nombreColegio,
    required this.totalPedidos,
    required this.pedidosActivos,
    this.direccionColegio,
  });

  final int colegioId;
  final String nombreColegio;
  final String? direccionColegio;
  final int totalPedidos;

  /// Pedidos en curso (ni entregados ni cancelados).
  final int pedidosActivos;
}
