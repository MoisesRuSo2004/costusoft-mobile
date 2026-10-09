/// Entrada (llega material) o salida (sale material) del almacén.
enum TipoMovimiento {
  entrada('entradas', 'Entrada', 'Entradas'),
  salida('salidas', 'Salida', 'Salidas');

  const TipoMovimiento(this.ruta, this.etiqueta, this.plural);

  /// Segmento del endpoint: `/api/entradas` o `/api/salidas`.
  final String ruta;
  final String etiqueta;
  final String plural;
}

/// Estado del flujo de aprobación: el usuario registra, Bodega verifica.
enum EstadoMovimiento {
  pendiente('PENDIENTE', 'Pendiente'),
  confirmada('CONFIRMADA', 'Confirmada'),
  rechazada('RECHAZADA', 'Rechazada');

  const EstadoMovimiento(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static EstadoMovimiento desdeCodigo(String? codigo) =>
      values.firstWhere((e) => e.codigo == codigo?.toUpperCase(), orElse: () => pendiente);
}

/// Un insumo dentro de un movimiento.
class DetalleMovimiento {
  const DetalleMovimiento({
    required this.insumoId,
    required this.nombreInsumo,
    required this.cantidad,
    required this.unidad,
  });

  final int insumoId;
  final String nombreInsumo;
  final int cantidad;
  final String unidad;
}

class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.detalles,
    this.fecha,
    this.descripcion,
    this.tercero,
    this.confirmadaPor,
    this.motivoRechazo,
    this.confirmadaEn,
    this.creadoEn,
  });

  final int id;
  final TipoMovimiento tipo;
  final EstadoMovimiento estado;
  final List<DetalleMovimiento> detalles;
  final DateTime? fecha;
  final String? descripcion;

  /// Proveedor (entradas) o colegio de destino (salidas).
  final String? tercero;
  final String? confirmadaPor;
  final String? motivoRechazo;
  final DateTime? confirmadaEn;
  final DateTime? creadoEn;

  int get totalUnidades => detalles.fold(0, (total, d) => total + d.cantidad);

  bool incluyeInsumo(int insumoId) => detalles.any((d) => d.insumoId == insumoId);
}
