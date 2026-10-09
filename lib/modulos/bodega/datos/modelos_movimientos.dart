import '../dominio/movimiento.dart';

String? _texto(Object? v) {
  final texto = (v as String?)?.trim();
  return texto == null || texto.isEmpty ? null : texto;
}

/// `EntradaDTO.Response` / `SalidaDTO.Response` (camelCase).
Movimiento movimientoDesdeJson(Map<String, dynamic> json, TipoMovimiento tipo) => Movimiento(
  id: (json['id'] as num).toInt(),
  tipo: tipo,
  estado: EstadoMovimiento.desdeCodigo(json['estado'] as String?),
  fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
  descripcion: _texto(json['descripcion']),
  tercero: _texto(json[tipo == TipoMovimiento.entrada ? 'proveedorNombre' : 'colegioNombre']),
  confirmadaPor: _texto(json['confirmadaPor']),
  motivoRechazo: _texto(json['motivoRechazo']),
  confirmadaEn: DateTime.tryParse(json['confirmadaAt']?.toString() ?? ''),
  creadoEn: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  detalles: [
    for (final d in (json['detalles'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
      DetalleMovimiento(
        insumoId: (d['insumoId'] as num?)?.toInt() ?? 0,
        nombreInsumo: _texto(d['nombreInsumo']) ?? 'Insumo',
        cantidad: (d['cantidad'] as num?)?.toInt() ?? 0,
        unidad: _texto(d['unidadMedida']) ?? '',
      ),
  ],
);
