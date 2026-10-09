import '../../pedidos/dominio/pedido.dart';

/// Situación de un hito en la línea de tiempo del pedido.
enum SituacionHito { completado, actual, pendiente, cancelado }

/// Un paso del pedido contado al colegio, con lenguaje para el cliente
/// (sin las acciones internas del taller ni quién las hizo).
class HitoPedido {
  const HitoPedido({
    required this.estado,
    required this.titulo,
    required this.descripcion,
    required this.situacion,
    this.fecha,
  });

  final EstadoPedido estado;
  final String titulo;
  final String descripcion;
  final SituacionHito situacion;

  /// Cuándo se alcanzó (null si aún no ocurre).
  final DateTime? fecha;
}

/// Hitos que ve el colegio. "Calculado" es una revisión interna del taller:
/// para el colegio el pedido sigue "registrado" hasta que se confirma.
const _hitos = [
  (EstadoPedido.borrador, 'Pedido registrado', 'Recibimos tu pedido y lo estamos revisando.'),
  (EstadoPedido.confirmado, 'Confirmado', 'Validamos los materiales y confirmamos tu pedido.'),
  (EstadoPedido.enProduccion, 'En producción', 'Estamos confeccionando tus uniformes.'),
  (EstadoPedido.listoParaEntrega, 'Listo para entrega', 'Tus uniformes están listos para entregar.'),
  (EstadoPedido.entregado, 'Entregado', 'El pedido fue entregado al colegio.'),
];

int _indiceDe(EstadoPedido estado) => switch (estado) {
  EstadoPedido.borrador || EstadoPedido.calculado => 0,
  EstadoPedido.confirmado => 1,
  EstadoPedido.enProduccion => 2,
  EstadoPedido.listoParaEntrega => 3,
  EstadoPedido.entregado => 4,
  EstadoPedido.cancelado => -1,
};

/// Arma la línea de tiempo del pedido a partir de su estado y su historial
/// (en cualquier orden). Un pedido cancelado muestra los hitos que alcanzó y
/// cierra con el hito "Cancelado" y su motivo.
List<HitoPedido> calcularHitos(Pedido pedido, List<EventoPedido> historial) {
  final eventos = [...historial]..sort((a, b) => (a.fecha ?? DateTime(0)).compareTo(b.fecha ?? DateTime(0)));

  /// Primera vez que el pedido llegó al hito [indice].
  DateTime? fechaDe(int indice) {
    for (final e in eventos) {
      if (_indiceDe(e.estadoNuevo) == indice) return e.fecha;
    }
    return indice == 0 ? pedido.fechaCreacion : null;
  }

  if (pedido.estado == EstadoPedido.cancelado) {
    final cancelacion = eventos.where((e) => e.estadoNuevo == EstadoPedido.cancelado).lastOrNull;
    final anterior = cancelacion?.estadoAnterior;
    final alcanzado = anterior == null
        ? eventos.map((e) => _indiceDe(e.estadoNuevo)).fold(0, (a, b) => b > a ? b : a)
        : _indiceDe(anterior);
    return [
      for (var i = 0; i <= alcanzado && i < _hitos.length; i++)
        HitoPedido(
          estado: _hitos[i].$1,
          titulo: _hitos[i].$2,
          descripcion: _hitos[i].$3,
          situacion: SituacionHito.completado,
          fecha: fechaDe(i),
        ),
      HitoPedido(
        estado: EstadoPedido.cancelado,
        titulo: 'Cancelado',
        descripcion: switch (cancelacion?.observacion?.trim()) {
          final motivo? when motivo.isNotEmpty => 'Motivo: $motivo',
          _ => 'El pedido fue cancelado.',
        },
        situacion: SituacionHito.cancelado,
        fecha: cancelacion?.fecha,
      ),
    ];
  }

  final actual = _indiceDe(pedido.estado);
  final esFinal = pedido.estado == EstadoPedido.entregado;
  return [
    for (var i = 0; i < _hitos.length; i++)
      HitoPedido(
        estado: _hitos[i].$1,
        titulo: _hitos[i].$2,
        descripcion: _hitos[i].$3,
        situacion: i < actual || (esFinal && i == actual)
            ? SituacionHito.completado
            : (i == actual ? SituacionHito.actual : SituacionHito.pendiente),
        fecha: i <= actual ? fechaDe(i) : null,
      ),
  ];
}

/// Frase principal del seguimiento según el estado del pedido.
String mensajeDeSeguimiento(EstadoPedido estado) => switch (estado) {
  EstadoPedido.borrador || EstadoPedido.calculado => 'Recibimos tu pedido. El equipo lo está revisando.',
  EstadoPedido.confirmado => 'Tu pedido está confirmado y pronto entrará a producción.',
  EstadoPedido.enProduccion => 'Estamos confeccionando tus uniformes.',
  EstadoPedido.listoParaEntrega => '¡Tus uniformes están listos para entrega!',
  EstadoPedido.entregado => 'Pedido entregado. ¡Gracias por confiar en CostuSoft!',
  EstadoPedido.cancelado => 'Este pedido fue cancelado.',
};
