import 'package:costusoft_mobile/modulos/bodega/datos/modelos_movimientos.dart';
import 'package:costusoft_mobile/modulos/bodega/dominio/codigo_qr.dart';
import 'package:costusoft_mobile/modulos/bodega/dominio/movimiento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Código QR de insumo', () {
    test('el código generado se lee de vuelta', () {
      expect(idDeInsumoEnCodigo(codigoQrDeInsumo(48)), 48);
    });

    test('acepta los formatos tolerados', () {
      expect(idDeInsumoEnCodigo('costusoft://insumo/12'), 12);
      expect(idDeInsumoEnCodigo('https://app.costusoft.com/admin/inventario/insumos/7'), 7);
      expect(idDeInsumoEnCodigo('INS-33'), 33);
      expect(idDeInsumoEnCodigo('ins33'), 33);
      expect(idDeInsumoEnCodigo('  91 '), 91);
    });

    test('rechaza códigos ajenos', () {
      expect(idDeInsumoEnCodigo(''), isNull);
      expect(idDeInsumoEnCodigo('hola'), isNull);
      expect(idDeInsumoEnCodigo('0'), isNull);
      expect(idDeInsumoEnCodigo('https://otra.com/producto/5'), isNull);
    });
  });

  group('movimientoDesdeJson', () {
    final json = {
      'id': 5,
      'fecha': '2026-10-01',
      'descripcion': ' ',
      'proveedorNombre': 'Textiles del Caribe',
      'colegioNombre': 'Colegio X',
      'estado': 'PENDIENTE',
      'createdAt': '2026-10-01T08:30:00',
      'detalles': [
        {'id': 1, 'insumoId': 10, 'nombreInsumo': 'Tela azul', 'cantidad': 30, 'unidadMedida': 'metros'},
        {'id': 2, 'insumoId': 11, 'nombreInsumo': 'Botones', 'cantidad': 200, 'unidadMedida': 'unidades'},
      ],
    };

    test('entrada: toma el proveedor y limpia textos vacíos', () {
      final m = movimientoDesdeJson(json, TipoMovimiento.entrada);
      expect(m.estado, EstadoMovimiento.pendiente);
      expect(m.tercero, 'Textiles del Caribe');
      expect(m.descripcion, isNull);
      expect(m.totalUnidades, 230);
      expect(m.incluyeInsumo(11), isTrue);
      expect(m.incluyeInsumo(99), isFalse);
    });

    test('salida: toma el colegio', () {
      final m = movimientoDesdeJson({
        ...json,
        'estado': 'RECHAZADA',
        'motivoRechazo': 'No coincide',
      }, TipoMovimiento.salida);
      expect(m.tercero, 'Colegio X');
      expect(m.estado, EstadoMovimiento.rechazada);
      expect(m.motivoRechazo, 'No coincide');
    });
  });
}
