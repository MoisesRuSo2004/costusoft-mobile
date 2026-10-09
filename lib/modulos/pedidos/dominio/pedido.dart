import '../../autenticacion/dominio/rol_usuario.dart';

/// Estados de un pedido, en el orden del flujo del backend.
enum EstadoPedido {
  borrador('BORRADOR', 'Borrador'),
  calculado('CALCULADO', 'Calculado'),
  confirmado('CONFIRMADO', 'Confirmado'),
  enProduccion('EN_PRODUCCION', 'En producción'),
  listoParaEntrega('LISTO_PARA_ENTREGA', 'Listo para entrega'),
  entregado('ENTREGADO', 'Entregado'),
  cancelado('CANCELADO', 'Cancelado');

  const EstadoPedido(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  bool get esFinal => this == entregado || this == cancelado;

  /// Etapas del flujo normal (sin "cancelado"), para la línea de progreso.
  static const flujo = [borrador, calculado, confirmado, enProduccion, listoParaEntrega, entregado];

  static EstadoPedido desdeCodigo(String? codigo) =>
      values.firstWhere((e) => e.codigo == codigo?.toUpperCase(), orElse: () => borrador);
}

/// Acción que hace avanzar un pedido al siguiente estado.
enum AccionPedido {
  calcular(
    ruta: 'calcular',
    etiqueta: 'Calcular insumos',
    confirmacion: 'Se verificará si el inventario alcanza para fabricar todas las prendas. No modifica el stock.',
    roles: {RolUsuario.administrador, RolUsuario.usuario},
  ),
  confirmar(
    ruta: 'confirmar',
    etiqueta: 'Confirmar pedido',
    confirmacion: 'El pedido quedará confirmado y listo para iniciar producción.',
    roles: {RolUsuario.administrador, RolUsuario.usuario},
  ),
  iniciarProduccion(
    ruta: 'iniciar-produccion',
    etiqueta: 'Iniciar producción',
    confirmacion:
        'Se descontarán del inventario todos los insumos del pedido (se genera una salida confirmada). '
        'Si se cancela después, el stock se devuelve.',
    roles: {RolUsuario.administrador, RolUsuario.usuario, RolUsuario.bodega},
    afectaStock: true,
  ),
  marcarListo(
    ruta: 'marcar-listo',
    etiqueta: 'Marcar como listo',
    confirmacion: 'El pedido quedará listo para entregar al colegio.',
    roles: {RolUsuario.administrador, RolUsuario.usuario, RolUsuario.bodega},
  ),
  entregar(
    ruta: 'entregar',
    etiqueta: 'Registrar entrega',
    confirmacion: 'El pedido se marcará como entregado al colegio. Esta acción es final.',
    roles: {RolUsuario.administrador, RolUsuario.usuario, RolUsuario.bodega},
  );

  const AccionPedido({
    required this.ruta,
    required this.etiqueta,
    required this.confirmacion,
    required this.roles,
    this.afectaStock = false,
  });

  /// Segmento del endpoint: `POST /api/pedidos/{id}/{ruta}`.
  final String ruta;
  final String etiqueta;

  /// Texto del diálogo de confirmación.
  final String confirmacion;

  /// Roles que el backend autoriza (`@PreAuthorize`).
  final Set<RolUsuario> roles;
  final bool afectaStock;

  /// Siguiente acción posible según el estado actual (mismas reglas del backend).
  static AccionPedido? siguiente(EstadoPedido estado) => switch (estado) {
    EstadoPedido.borrador => calcular,
    EstadoPedido.calculado => confirmar,
    EstadoPedido.confirmado => iniciarProduccion,
    EstadoPedido.enProduccion => marcarListo,
    EstadoPedido.listoParaEntrega => entregar,
    EstadoPedido.entregado || EstadoPedido.cancelado => null,
  };
}

/// Solo administrador y usuario pueden cancelar, y solo pedidos no finalizados.
bool puedeCancelar(EstadoPedido estado, RolUsuario rol) =>
    !estado.esFinal && (rol == RolUsuario.administrador || rol == RolUsuario.usuario);

class ColegioPedido {
  const ColegioPedido({required this.id, required this.nombre, this.direccion});

  final int id;
  final String nombre;
  final String? direccion;
}

/// Una prenda del pedido.
class PrendaPedido {
  const PrendaPedido({
    required this.uniforme,
    required this.cantidad,
    this.tipo,
    this.talla,
    this.genero,
    this.cantidadMaximaFabricable,
    this.disponible,
  });

  final String uniforme;
  final int cantidad;
  final String? tipo;
  final String? talla;
  final String? genero;

  /// Tras calcular: cuántas se pueden fabricar con el stock actual.
  final int? cantidadMaximaFabricable;
  final bool? disponible;
}

/// Insumo necesario para el pedido (resultado de la calculadora).
class InsumoNecesario {
  const InsumoNecesario({
    required this.nombre,
    required this.unidad,
    required this.stockActual,
    required this.necesario,
    required this.faltante,
    required this.suficiente,
  });

  final String nombre;
  final String unidad;
  final double stockActual;
  final double necesario;
  final double faltante;
  final bool suficiente;
}

class Pedido {
  const Pedido({
    required this.id,
    required this.numero,
    required this.estado,
    required this.colegio,
    required this.prendas,
    this.fechaCreacion,
    this.fechaEntregaEstimada,
    this.observaciones,
    this.creadoPor,
    this.porcentajeCumplimiento,
    this.insumoLimitante,
    this.insumosNecesarios = const [],
    this.actualizadoEn,
  });

  final int id;

  /// Ej.: `PED-2026-09440`.
  final String numero;
  final EstadoPedido estado;
  final ColegioPedido colegio;
  final List<PrendaPedido> prendas;
  final DateTime? fechaCreacion;
  final DateTime? fechaEntregaEstimada;
  final String? observaciones;
  final String? creadoPor;

  /// Resultado de la calculadora (null si no se ha calculado).
  final int? porcentajeCumplimiento;
  final String? insumoLimitante;
  final List<InsumoNecesario> insumosNecesarios;
  final DateTime? actualizadoEn;

  int get totalPrendas => prendas.fold(0, (total, p) => total + p.cantidad);

  /// Días hasta la entrega estimada (negativo si ya pasó).
  int? diasParaEntrega(DateTime hoy) {
    final fecha = fechaEntregaEstimada;
    if (fecha == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
  }

  /// Entrega estimada vencida y el pedido aún no se entrega ni se cancela.
  bool estaAtrasado(DateTime hoy) => !estado.esFinal && (diasParaEntrega(hoy) ?? 0) < 0;
}

/// Un cambio registrado en el historial del pedido (auditoría del backend).
class EventoPedido {
  const EventoPedido({
    required this.accion,
    required this.estadoNuevo,
    this.estadoAnterior,
    this.observacion,
    this.realizadoPor,
    this.fecha,
  });

  final String accion;
  final EstadoPedido estadoNuevo;
  final EstadoPedido? estadoAnterior;
  final String? observacion;
  final String? realizadoPor;
  final DateTime? fecha;
}
