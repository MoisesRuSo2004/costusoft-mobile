/// Estado del stock de un insumo (mismas reglas que la web).
enum EstadoStock {
  disponible('Disponible'),
  stockBajo('Stock bajo'),
  sinStock('Sin stock');

  const EstadoStock(this.etiqueta);

  final String etiqueta;
}

/// Material del inventario (tela, hilo, botón…).
class Insumo {
  const Insumo({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.unidadMedida,
    required this.tipo,
    required this.stockMinimo,
    required this.activo,
    this.actualizadoEn,
  });

  final int id;
  final String nombre;
  final int stock;
  final String unidadMedida;
  final String tipo;
  final int stockMinimo;
  final bool activo;
  final DateTime? actualizadoEn;

  EstadoStock get estado {
    if (stock <= 0) return EstadoStock.sinStock;
    if (stock <= stockMinimo) return EstadoStock.stockBajo;
    return EstadoStock.disponible;
  }

  /// Qué tan lleno está respecto al doble del mínimo (0 a 1), para la barra.
  /// Llegar al doble del mínimo se considera "lleno".
  double get nivelRelativo {
    if (stockMinimo <= 0) return stock > 0 ? 1 : 0;
    return (stock / (stockMinimo * 2)).clamp(0, 1).toDouble();
  }

  Insumo copiarCon({int? stock, DateTime? actualizadoEn}) => Insumo(
    id: id,
    nombre: nombre,
    stock: stock ?? this.stock,
    unidadMedida: unidadMedida,
    tipo: tipo,
    stockMinimo: stockMinimo,
    activo: activo,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
}
