import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';

/// Convierte el `InsumoDTO.Response` del backend (camelCase).
Insumo insumoDesdeJson(Map<String, dynamic> json) => Insumo(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String? ?? '',
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  unidadMedida: json['unidadMedida'] as String? ?? '',
  tipo: (json['tipo'] as String?)?.trim().isNotEmpty == true ? (json['tipo'] as String).trim() : 'Otros',
  stockMinimo: (json['stockMinimo'] as num?)?.toInt() ?? 0,
  activo: json['activo'] as bool? ?? true,
  actualizadoEn: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
);

/// Convierte la predicción del microservicio, que el backend reenvía tal cual
/// en **snake_case** (`consumo_diario_promedio`, `nivel_riesgo`…).
PrediccionInsumo prediccionDesdeJson(Map<String, dynamic> json) {
  final prophet = json['prophet'] as Map<String, dynamic>? ?? const {};
  final xgboost = json['xgboost'] as Map<String, dynamic>? ?? const {};
  final caracteristicas = json['features'] as Map<String, dynamic>? ?? const {};
  final probabilidades = xgboost['probabilidades'] as Map<String, dynamic>? ?? const {};

  int? entero(Object? valor) => (valor as num?)?.toInt();
  double decimal(Object? valor) => (valor as num?)?.toDouble() ?? 0;

  return PrediccionInsumo(
    insumoId: (json['insumo_id'] as num?)?.toInt() ?? 0,
    nombre: json['nombre'] as String? ?? '',
    stockActual: (json['stock_actual'] as num?)?.toInt() ?? 0,
    stockMinimo: (json['stock_minimo'] as num?)?.toInt() ?? 0,
    unidadMedida: json['unidad_medida'] as String? ?? '',
    nivelRiesgo: NivelRiesgo.desdeCodigo(xgboost['nivel_riesgo'] as String?),
    probabilidades: {
      for (final entrada in probabilidades.entries)
        if (NivelRiesgo.desdeCodigo(entrada.key) != NivelRiesgo.desconocido)
          NivelRiesgo.desdeCodigo(entrada.key): decimal(entrada.value),
    },
    modeloEntrenado: xgboost['modelo_entrenado'] as bool? ?? false,
    consumoDiario: decimal(prophet['consumo_diario_promedio']),
    diasHastaMinimo: entero(prophet['dias_hasta_stock_minimo']),
    diasHastaCero: entero(prophet['dias_hasta_cero']),
    fechaAlerta: DateTime.tryParse(prophet['fecha_alerta_estimada'] as String? ?? ''),
    fechaAgotamiento: DateTime.tryParse(prophet['fecha_agotamiento_estimada'] as String? ?? ''),
    confianza: (prophet['confianza'] as num?)?.toDouble(),
    suficienteHistorial: prophet['suficiente_historial'] as bool? ?? true,
    consumo7Dias: caracteristicas['consumo_7d'] as num? ?? 0,
    consumo30Dias: caracteristicas['consumo_30d'] as num? ?? 0,
    consumo90Dias: caracteristicas['consumo_90d'] as num? ?? 0,
    tendenciaConsumo: decimal(caracteristicas['tendencia_consumo']),
    alerta: json['alerta'] as bool? ?? false,
    mensaje: json['mensaje'] as String? ?? '',
    recomendacion: json['recomendacion'] as String? ?? '',
  );
}
