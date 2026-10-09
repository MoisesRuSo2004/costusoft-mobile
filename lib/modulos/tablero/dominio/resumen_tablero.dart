import '../../bodega/dominio/movimiento.dart';
import '../../inventario/dominio/prediccion_insumo.dart';
import '../../pedidos/dominio/pedido.dart';

export '../../bodega/dominio/movimiento.dart' show TipoMovimiento;
export '../../pedidos/dominio/pedido.dart' show EstadoPedido;

/// Insumo con stock bajo que el backend reporta en el resumen.
class AlertaStock {
  const AlertaStock({
    required this.insumoId,
    required this.nombre,
    required this.stockActual,
    required this.stockMinimo,
    required this.unidad,
    required this.nivelRiesgo,
  });

  final int insumoId;
  final String nombre;
  final int stockActual;
  final int stockMinimo;
  final String unidad;
  final NivelRiesgo nivelRiesgo;
}

/// Entrada o salida reciente del almacén.
class MovimientoReciente {
  const MovimientoReciente({required this.tipo, required this.descripcion, required this.totalItems, this.fecha});

  final TipoMovimiento tipo;
  final String descripcion;
  final int totalItems;
  final DateTime? fecha;
}

/// Cantidad de entradas y salidas de un mes.
class MovimientosDelMes {
  const MovimientosDelMes({required this.mes, required this.entradas, required this.salidas});

  /// Primer día del mes.
  final DateTime mes;
  final int entradas;
  final int salidas;
}

/// `GET /api/dashboard/resumen`.
class ResumenTablero {
  const ResumenTablero({
    required this.totalInsumos,
    required this.totalEntradas,
    required this.totalSalidas,
    required this.totalColegios,
    required this.totalUniformes,
    required this.totalProveedores,
    required this.totalUsuarios,
    required this.insumosConStockBajo,
    required this.insumosSinStock,
    required this.alertas,
    required this.movimientosPorMes,
    required this.ultimosMovimientos,
  });

  final int totalInsumos;
  final int totalEntradas;
  final int totalSalidas;
  final int totalColegios;
  final int totalUniformes;
  final int totalProveedores;
  final int totalUsuarios;

  /// Tal como lo cuenta el backend: incluye los que están en cero.
  final int insumosConStockBajo;
  final int insumosSinStock;

  /// Stock bajo sin contar los que están en cero, igual que el inventario
  /// ("Stock bajo" y "Sin stock" son estados distintos).
  int get insumosSoloStockBajo => (insumosConStockBajo - insumosSinStock).clamp(0, insumosConStockBajo);
  final List<AlertaStock> alertas;

  /// Del mes más antiguo al más reciente.
  final List<MovimientosDelMes> movimientosPorMes;
  final List<MovimientoReciente> ultimosMovimientos;
}

/// Cantidad de pedidos por estado.
class ConteoPedidos {
  const ConteoPedidos(this.porEstado);

  final Map<EstadoPedido, int> porEstado;

  int operator [](EstadoPedido estado) => porEstado[estado] ?? 0;

  /// Pedidos que aún requieren trabajo del taller.
  int get activos =>
      this[EstadoPedido.confirmado] + this[EstadoPedido.enProduccion] + this[EstadoPedido.listoParaEntrega];

  /// Porcentaje de pedidos cerrados que se entregaron (vs. cancelados).
  double? get tasaCumplimiento {
    final cerrados = this[EstadoPedido.entregado] + this[EstadoPedido.cancelado];
    return cerrados == 0 ? null : this[EstadoPedido.entregado] / cerrados * 100;
  }
}
