import '../dominio/entidades_ia.dart';

/// `IaDTO.ConsultaResponse` / `ChatResponse` (camelCase).
RespuestaIa respuestaIaDesdeJson(Map<String, dynamic> json, {String campoTexto = 'respuesta'}) => RespuestaIa(
  texto: (json[campoTexto] as String? ?? '').trim(),
  modelo: json['modelo'] as String?,
  tiempo: (json['tiempoMs'] as num?) == null ? null : Duration(milliseconds: (json['tiempoMs'] as num).toInt()),
);

Colegio colegioDesdeJson(Map<String, dynamic> json) =>
    Colegio(id: (json['id'] as num).toInt(), nombre: json['nombre'] as String? ?? 'Colegio');

Map<String, int> _unidades(Object? plan) => {
  for (final entrada in (plan as Map<String, dynamic>? ?? const {}).entries)
    entrada.key: (entrada.value as num?)?.toInt() ?? 0,
};

/// Respuesta de `POST /api/optimizacion` (el backend la envía en snake_case).
PlanProduccion planDesdeRespuesta(Map<String, dynamic> json) {
  final etiquetas = (json['insumo_labels'] as Map<String, dynamic>? ?? const {}).map(
    (clave, valor) => MapEntry(clave, valor.toString()),
  );
  final recursos = json['recursos'] as Map<String, dynamic>? ?? const {};
  double numero(Object? v) => (v as num?)?.toDouble() ?? 0;

  final uso = [
    for (final entrada in recursos.entries)
      UsoInsumo(
        nombre: etiquetas[entrada.key] ?? _humanizar(entrada.key),
        usado: numero((entrada.value as Map<String, dynamic>)['usado']),
        disponible: numero((entrada.value as Map<String, dynamic>)['disponible']),
        holgura: numero((entrada.value as Map<String, dynamic>)['holgura']),
        utilizacion: numero((entrada.value as Map<String, dynamic>)['utilizacion_pct']),
        unidad: (entrada.value as Map<String, dynamic>)['unidad_medida'] as String? ?? '',
      ),
  ]..sort((a, b) => b.utilizacion.compareTo(a.utilizacion));

  return PlanProduccion(
    id: (json['id'] as num?)?.toInt(),
    colegioId: (json['colegio_id'] as num?)?.toInt(),
    nombreColegio: json['nombre_colegio'] as String?,
    estado: json['estado'] as String? ?? '',
    utilidadTotal: numero(json['utilidad_total']),
    unidadesPorPrenda: _unidades(json['plan']),
    usoInsumos: uso,
    mensaje: json['mensaje'] as String? ?? '',
    fecha: DateTime.tryParse(json['fecha_ejecucion']?.toString() ?? ''),
  );
}

/// Elemento de `GET /api/optimizacion/historial` (otras claves que la respuesta).
PlanProduccion planDesdeHistorial(Map<String, dynamic> json) => PlanProduccion(
  id: (json['id'] as num?)?.toInt(),
  colegioId: (json['colegio_id'] as num?)?.toInt(),
  nombreColegio: json['nombre_colegio'] as String?,
  estado: json['estado_solucion'] as String? ?? '',
  utilidadTotal: (json['utilidad_total'] as num?)?.toDouble() ?? 0,
  unidadesPorPrenda: _unidades(json['plan_produccion']),
  mensaje: json['mensaje'] as String? ?? '',
  fecha: DateTime.tryParse(json['fecha_ejecucion']?.toString() ?? ''),
);

/// `blusa_diario_femenino` → `Blusa diario femenino`.
String _humanizar(String clave) {
  final texto = clave.replaceAll('_', ' ').trim();
  return texto.isEmpty ? clave : texto[0].toUpperCase() + texto.substring(1);
}

/// Palabras sin tilde o abreviadas en las claves del modelo ILP.
const _correcciones = {
  'pantalon': 'pantalón',
  'sueter': 'suéter',
  'ef': 'educación física',
  'educacion': 'educación',
  'fisica': 'física',
};

/// Nombre legible de una prenda del plan: `pantalon_ef` → `Pantalón educación física`.
String nombrePrenda(String clave) {
  final palabras = clave.toLowerCase().split('_').where((p) => p.isNotEmpty).map((p) => _correcciones[p] ?? p);
  final texto = palabras.join(' ');
  return texto.isEmpty ? clave : texto[0].toUpperCase() + texto.substring(1);
}
