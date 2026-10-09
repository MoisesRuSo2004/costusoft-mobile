/// Consultas predefinidas del agente de IA (mismos nombres que la web).
enum TipoConsultaIa {
  resumenInventario('RESUMEN_INVENTARIO', 'Resumen', 'Estado general del inventario'),
  stockBajo('STOCK_BAJO', 'Stock bajo', 'Insumos por debajo del mínimo'),
  pedidosActivos('PEDIDOS_ACTIVOS', 'Pedidos', 'Pedidos activos y en producción'),
  entradasPendientes('ENTRADAS_PENDIENTES', 'Entradas', 'Entradas pendientes de confirmar'),
  salidasPendientes('SALIDAS_PENDIENTES', 'Salidas', 'Salidas pendientes de confirmar'),
  analisisGeneral('ANALISIS_GENERAL', 'Análisis', 'Diagnóstico completo del sistema'),
  prediccionRiesgo('PREDICCION_RIESGO', 'Predicción', 'Predicciones ML de riesgo'),
  analisisProveedores('ANALISIS_PROVEEDORES', 'Proveedores', 'Rendimiento de proveedores'),
  anomaliasConsumo('ANOMALIAS_CONSUMO', 'Anomalías', 'Picos y consumos inusuales'),
  analisisOptimizacion('ANALISIS_OPTIMIZACION', 'Optimización', 'Plan de producción óptimo ILP'),
  modeloMatematico('MODELO_MATEMATICO', 'Modelo matemático', 'Variables, restricciones y coeficientes del modelo ILP');

  const TipoConsultaIa(this.codigo, this.etiqueta, this.descripcion);

  final String codigo;
  final String etiqueta;
  final String descripcion;
}

/// Respuesta del agente de IA (Groq).
class RespuestaIa {
  const RespuestaIa({required this.texto, this.modelo, this.tiempo});

  /// Texto en Markdown.
  final String texto;
  final String? modelo;
  final Duration? tiempo;
}

enum AutorMensaje { usuario, asistente }

/// Un mensaje de la conversación con el asistente.
class MensajeChat {
  const MensajeChat({
    required this.id,
    required this.autor,
    required this.texto,
    this.titulo,
    this.respuesta,
    this.error,
    this.esperando = false,
  });

  final int id;
  final AutorMensaje autor;
  final String texto;

  /// Para respuestas de consultas rápidas (p. ej. "Stock bajo").
  final String? titulo;
  final RespuestaIa? respuesta;

  /// Mensaje de error si la IA no pudo responder.
  final String? error;

  /// `true` mientras la IA está respondiendo.
  final bool esperando;
}

/// Colegio (cliente del taller) sobre el que se optimiza la producción.
class Colegio {
  const Colegio({required this.id, required this.nombre});

  final int id;
  final String nombre;
}

/// Uso de un insumo en el plan óptimo (restricción del modelo ILP).
class UsoInsumo {
  const UsoInsumo({
    required this.nombre,
    required this.usado,
    required this.disponible,
    required this.holgura,
    required this.utilizacion,
    required this.unidad,
  });

  final String nombre;
  final double usado;
  final double disponible;
  final double holgura;

  /// Porcentaje usado del disponible (0 a 100).
  final double utilizacion;
  final String unidad;

  /// Sin holgura: es el insumo que impide producir más.
  bool get esLimitante => holgura <= 0.0001 && disponible > 0;
}

/// Resultado del motor de optimización (programación lineal entera).
class PlanProduccion {
  const PlanProduccion({
    required this.estado,
    required this.utilidadTotal,
    required this.unidadesPorPrenda,
    this.id,
    this.colegioId,
    this.nombreColegio,
    this.usoInsumos = const [],
    this.mensaje = '',
    this.fecha,
  });

  final int? id;
  final int? colegioId;
  final String? nombreColegio;

  /// `OPTIMAL`, `INFEASIBLE`…
  final String estado;
  final double utilidadTotal;

  /// Prenda (p. ej. `blusa_diario_femenino`) → unidades a producir.
  final Map<String, int> unidadesPorPrenda;
  final List<UsoInsumo> usoInsumos;
  final String mensaje;
  final DateTime? fecha;

  bool get esOptimo => estado.toUpperCase() == 'OPTIMAL';

  int get totalPrendas => unidadesPorPrenda.values.fold(0, (a, b) => a + b);
}
