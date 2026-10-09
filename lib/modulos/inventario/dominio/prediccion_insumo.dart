/// Nivel de riesgo de desabastecimiento que calcula XGBoost.
enum NivelRiesgo {
  bajo('BAJO', 'Bajo'),
  medio('MEDIO', 'Medio'),
  alto('ALTO', 'Alto'),
  critico('CRITICO', 'Crítico'),
  desconocido('', 'Sin datos');

  const NivelRiesgo(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  /// ALTO y CRÍTICO cuentan como "en riesgo" para filtros y alertas.
  bool get esPreocupante => this == alto || this == critico;

  static NivelRiesgo desdeCodigo(String? codigo) {
    final normalizado = codigo?.toUpperCase().replaceAll('Í', 'I');
    return values.firstWhere((n) => n.codigo == normalizado, orElse: () => desconocido);
  }
}

/// Resultado del microservicio de predicción para un insumo
/// (Prophet pronostica el agotamiento, XGBoost clasifica el riesgo).
class PrediccionInsumo {
  const PrediccionInsumo({
    required this.insumoId,
    this.nombre = '',
    this.stockActual = 0,
    this.stockMinimo = 0,
    this.unidadMedida = '',
    required this.nivelRiesgo,
    required this.probabilidades,
    required this.consumoDiario,
    required this.alerta,
    required this.mensaje,
    required this.recomendacion,
    this.diasHastaMinimo,
    this.diasHastaCero,
    this.fechaAlerta,
    this.fechaAgotamiento,
    this.confianza,
    this.suficienteHistorial = true,
    this.consumo7Dias = 0,
    this.consumo30Dias = 0,
    this.consumo90Dias = 0,
    this.tendenciaConsumo = 0,
    this.modeloEntrenado = false,
  });

  final int insumoId;
  final String nombre;
  final int stockActual;
  final int stockMinimo;
  final String unidadMedida;
  final NivelRiesgo nivelRiesgo;

  /// Probabilidad de cada nivel según XGBoost (vacío si se usaron reglas).
  final Map<NivelRiesgo, double> probabilidades;

  /// Consumo diario promedio estimado por Prophet.
  final double consumoDiario;
  final int? diasHastaMinimo;
  final int? diasHastaCero;
  final DateTime? fechaAlerta;
  final DateTime? fechaAgotamiento;

  /// Confianza del pronóstico de Prophet (0 a 1).
  final double? confianza;
  final bool suficienteHistorial;
  final num consumo7Dias;
  final num consumo30Dias;
  final num consumo90Dias;

  /// Positiva si el consumo viene en aumento.
  final double tendenciaConsumo;

  /// `false` cuando XGBoost aún no tiene modelo y el riesgo salió de reglas.
  final bool modeloEntrenado;
  final bool alerta;
  final String mensaje;
  final String recomendacion;

  bool get hayConsumo => consumoDiario > 0;
}
