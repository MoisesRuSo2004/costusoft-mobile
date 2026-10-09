import 'package:costusoft_mobile/modulos/inventario/dominio/prediccion_insumo.dart';
import 'package:costusoft_mobile/modulos/tablero/datos/fuente_remota_tablero.dart';
import 'package:costusoft_mobile/modulos/tablero/dominio/resumen_tablero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee el resumen del backend con los meses en orden', () {
    final r = resumenDesdeJson({
      'totalInsumos': 55,
      'totalEntradas': 3570,
      'insumosConStockBajo': 10,
      'insumosConStockCero': 1,
      'alertasStock': [
        {
          'id': 50,
          'nombre': 'Tela Satín',
          'stockActual': 2,
          'stockMinimo': 10,
          'unidadMedida': 'Metros',
          'nivelRiesgo': 'ALTO',
        },
      ],
      'entradasPorMes': {'2026-05': 24, '2026-04': 14},
      'salidasPorMes': {'2026-04': 11, '2026-05': 18},
      'ultimosMovimientos': [
        {'tipo': 'SALIDA', 'descripcion': 'Producción', 'fecha': '2026-05-29', 'totalItems': 2},
        {'tipo': 'ENTRADA', 'descripcion': '', 'fecha': '2026-05-20', 'totalItems': 1},
      ],
    });

    expect(r.totalInsumos, 55);
    expect(r.insumosSinStock, 1);
    expect(r.insumosSoloStockBajo, 9, reason: 'el backend incluye el que está en cero');
    expect(r.alertas.single.nivelRiesgo, NivelRiesgo.alto);
    expect(r.movimientosPorMes.map((m) => m.mes.month), [4, 5]);
    expect(r.movimientosPorMes.first.entradas, 14);
    expect(r.movimientosPorMes.first.salidas, 11);
    expect(r.ultimosMovimientos.first.tipo, TipoMovimiento.salida);
    expect(r.ultimosMovimientos.last.descripcion, 'Sin descripción');
  });

  test('pedidos activos y tasa de cumplimiento (datos reales del taller)', () {
    const conteo = ConteoPedidos({
      EstadoPedido.enProduccion: 9,
      EstadoPedido.listoParaEntrega: 4,
      EstadoPedido.entregado: 3263,
      EstadoPedido.cancelado: 607,
    });
    expect(conteo.activos, 13);
    expect(conteo.tasaCumplimiento!.toStringAsFixed(1), '84.3');
    expect(conteo[EstadoPedido.borrador], 0);
  });

  test('sin pedidos cerrados no hay tasa de cumplimiento', () {
    expect(const ConteoPedidos({}).tasaCumplimiento, isNull);
  });
}
