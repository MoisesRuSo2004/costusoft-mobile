import 'package:costusoft_mobile/modulos/institucion/dominio/seguimiento_pedido.dart';
import 'package:costusoft_mobile/modulos/pedidos/dominio/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido _pedido(EstadoPedido estado) => Pedido(
  id: 1,
  numero: 'PED-2026-00001',
  estado: estado,
  colegio: const ColegioPedido(id: 1, nombre: 'Colegio Demo'),
  prendas: const [],
  fechaCreacion: DateTime(2026, 5, 15, 8),
);

EventoPedido _evento(EstadoPedido nuevo, DateTime fecha, {EstadoPedido? anterior, String? observacion}) =>
    EventoPedido(accion: 'interna', estadoNuevo: nuevo, estadoAnterior: anterior, fecha: fecha, observacion: observacion);

void main() {
  // Historial real de un pedido en producción (el backend lo envía del más reciente al más antiguo).
  final historial = [
    _evento(EstadoPedido.enProduccion, DateTime(2026, 5, 22), anterior: EstadoPedido.confirmado),
    _evento(EstadoPedido.confirmado, DateTime(2026, 5, 21), anterior: EstadoPedido.calculado),
    _evento(EstadoPedido.calculado, DateTime(2026, 5, 20), anterior: EstadoPedido.borrador),
    _evento(EstadoPedido.borrador, DateTime(2026, 5, 15)),
  ];

  test('en producción: dos hitos completados, el actual y dos pendientes, con sus fechas', () {
    final hitos = calcularHitos(_pedido(EstadoPedido.enProduccion), historial);

    expect(hitos.map((h) => h.titulo), [
      'Pedido registrado',
      'Confirmado',
      'En producción',
      'Listo para entrega',
      'Entregado',
    ]);
    expect(hitos.map((h) => h.situacion), [
      SituacionHito.completado,
      SituacionHito.completado,
      SituacionHito.actual,
      SituacionHito.pendiente,
      SituacionHito.pendiente,
    ]);
    // "Calculado" es interno: el registro conserva la fecha de creación.
    expect(hitos[0].fecha, DateTime(2026, 5, 15));
    expect(hitos[1].fecha, DateTime(2026, 5, 21));
    expect(hitos[2].fecha, DateTime(2026, 5, 22));
    expect(hitos[3].fecha, isNull);
  });

  test('calculado sigue siendo "registrado" para el colegio', () {
    final hitos = calcularHitos(_pedido(EstadoPedido.calculado), historial.sublist(2));
    expect(hitos.first.situacion, SituacionHito.actual);
    expect(hitos.skip(1).every((h) => h.situacion == SituacionHito.pendiente), isTrue);
  });

  test('entregado: todos los hitos completados', () {
    final hitos = calcularHitos(_pedido(EstadoPedido.entregado), historial);
    expect(hitos.every((h) => h.situacion == SituacionHito.completado), isTrue);
  });

  test('sin historial usa la fecha de creación y el estado actual', () {
    final hitos = calcularHitos(_pedido(EstadoPedido.confirmado), const []);
    expect(hitos[0].fecha, DateTime(2026, 5, 15, 8));
    expect(hitos[1].situacion, SituacionHito.actual);
  });

  test('cancelado en producción: muestra hasta donde llegó y cierra con el motivo', () {
    final hitos = calcularHitos(_pedido(EstadoPedido.cancelado), [
      _evento(
        EstadoPedido.cancelado,
        DateTime(2026, 5, 25),
        anterior: EstadoPedido.enProduccion,
        observacion: 'El colegio cambió el diseño.',
      ),
      ...historial,
    ]);

    expect(hitos.map((h) => h.titulo), ['Pedido registrado', 'Confirmado', 'En producción', 'Cancelado']);
    expect(hitos.last.situacion, SituacionHito.cancelado);
    expect(hitos.last.descripcion, 'Motivo: El colegio cambió el diseño.');
    expect(hitos.last.fecha, DateTime(2026, 5, 25));
  });
}
