import 'package:costusoft_mobile/modulos/inventario/dominio/insumo.dart';
import 'package:costusoft_mobile/modulos/inventario/presentacion/hoja_etiqueta_qr.dart';
import 'package:flutter_test/flutter_test.dart';

Insumo _insumo(int id, String nombre) =>
    Insumo(id: id, nombre: nombre, stock: 10, unidadMedida: 'Metros', tipo: 'Tela', stockMinimo: 2, activo: true);

void main() {
  group('nombreArchivoEtiqueta', () {
    test('sin tildes, en minúsculas y con guiones', () {
      expect(
        nombreArchivoEtiqueta(_insumo(21, 'Tela algodón perchado azul Turquí')),
        'etiqueta-21-tela-algodon-perchado-azul-turqui.png',
      );
    });

    test('quita símbolos y guiones sobrantes', () {
      expect(nombreArchivoEtiqueta(_insumo(5, '  Cremallera 20 cm (gris)! ')), 'etiqueta-5-cremallera-20-cm-gris.png');
      expect(nombreArchivoEtiqueta(_insumo(3, 'Botón ñandú')), 'etiqueta-3-boton-nandu.png');
    });

    test('si el nombre no deja letras, queda solo el código', () {
      expect(nombreArchivoEtiqueta(_insumo(9, '***')), 'etiqueta-9.png');
    });
  });
}
