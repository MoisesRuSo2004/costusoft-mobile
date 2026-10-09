import '../dominio/pedido.dart';

int _entero(Object? v) => (v as num?)?.toInt() ?? 0;
double _decimal(Object? v) => (v as num?)?.toDouble() ?? 0;

/// El backend envía fechas como `2026-05-17 21:40:17` o `2026-06-18`.
DateTime? _fecha(Object? v) => DateTime.tryParse(v?.toString() ?? '');

String? _texto(Object? v) {
  final texto = (v as String?)?.trim();
  return texto == null || texto.isEmpty ? null : texto;
}

/// `PedidoDTO.Response` (camelCase).
Pedido pedidoDesdeJson(Map<String, dynamic> json) {
  final colegio = json['colegio'] as Map<String, dynamic>? ?? const {};
  return Pedido(
    id: _entero(json['id']),
    numero: json['numeroPedido'] as String? ?? '#${json['id']}',
    estado: EstadoPedido.desdeCodigo(json['estado'] as String?),
    colegio: ColegioPedido(
      id: _entero(colegio['id']),
      nombre: _texto(colegio['nombre']) ?? 'Sin colegio',
      direccion: _texto(colegio['direccion']),
    ),
    prendas: [
      for (final d in (json['detalles'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        PrendaPedido(
          uniforme: _texto(d['nombreUniforme']) ?? 'Uniforme',
          cantidad: _entero(d['cantidad']),
          tipo: _texto(d['tipo']),
          talla: _texto(d['talla']),
          genero: _texto(d['genero']),
          cantidadMaximaFabricable: (d['cantidadMaximaFabricable'] as num?)?.toInt(),
          disponible: d['disponibleIndividual'] as bool?,
        ),
    ],
    fechaCreacion: _fecha(json['fechaCreacion']),
    fechaEntregaEstimada: _fecha(json['fechaEstimadaEntrega']),
    observaciones: _texto(json['observaciones']),
    creadoPor: _texto(json['creadoPor']),
    porcentajeCumplimiento: (json['porcentajeCumplimiento'] as num?)?.toInt(),
    insumoLimitante: _texto(json['insumoLimitante']),
    insumosNecesarios: [
      for (final r in (json['resumenInsumos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        InsumoNecesario(
          nombre: _texto(r['nombre']) ?? 'Insumo',
          unidad: _texto(r['unidadMedida']) ?? '',
          stockActual: _decimal(r['stockActual']),
          necesario: _decimal(r['totalNecesario']),
          faltante: _decimal(r['faltante']),
          suficiente: r['suficiente'] as bool? ?? true,
        ),
    ],
    actualizadoEn: _fecha(json['updatedAt']),
  );
}

/// `PedidoDTO.HistorialResponse`.
EventoPedido eventoDesdeJson(Map<String, dynamic> json) => EventoPedido(
  accion: _texto(json['accion']) ?? 'Cambio de estado',
  estadoNuevo: EstadoPedido.desdeCodigo(json['estadoNuevo'] as String?),
  estadoAnterior: json['estadoAnterior'] == null ? null : EstadoPedido.desdeCodigo(json['estadoAnterior'] as String),
  observacion: _texto(json['observacion']),
  realizadoPor: _texto(json['realizadoPor']),
  fecha: _fecha(json['fechaAccion']),
);
