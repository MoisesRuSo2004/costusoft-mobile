import 'package:costusoft_mobile/modulos/inventario/datos/modelos_inventario.dart';
import 'package:costusoft_mobile/modulos/inventario/dominio/insumo.dart';
import 'package:costusoft_mobile/modulos/inventario/dominio/prediccion_insumo.dart';
import 'package:costusoft_mobile/modulos/inventario/presentacion/proveedores_inventario.dart';
import 'package:costusoft_mobile/nucleo/utilidades/formatos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Insumo _insumo(int id, String nombre, {int stock = 100, int minimo = 10, String tipo = 'Tela'}) =>
    Insumo(id: id, nombre: nombre, stock: stock, unidadMedida: 'Metros', tipo: tipo, stockMinimo: minimo, activo: true);

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  group('estado del stock (mismas reglas que la web)', () {
    test('cero es "sin stock"', () => expect(_insumo(1, 'a', stock: 0).estado, EstadoStock.sinStock));
    test('igual al mínimo es "stock bajo"', () {
      expect(_insumo(1, 'a', stock: 10).estado, EstadoStock.stockBajo);
    });
    test('sobre el mínimo es "disponible"', () => expect(_insumo(1, 'a', stock: 11).estado, EstadoStock.disponible));
    test('la barra llega a la mitad justo en el mínimo', () {
      expect(_insumo(1, 'a', stock: 10).nivelRelativo, 0.5);
      expect(_insumo(1, 'a', stock: 500).nivelRelativo, 1);
    });
  });

  group('filtrarInsumos', () {
    final insumos = [
      _insumo(1, 'Botón nácar', tipo: 'Botón', stock: 5),
      _insumo(2, 'Tela Drill Verde', stock: 0),
      _insumo(3, 'Hilo blanco', tipo: 'Hilo'),
    ];

    test('busca sin importar tildes ni mayúsculas', () {
      final r = filtrarInsumos(insumos, const FiltroInventario(texto: 'BOTON'), const {});
      expect(r.map((i) => i.id), [1]);
    });

    test('filtra por tipo', () {
      final r = filtrarInsumos(insumos, const FiltroInventario(tipo: 'Hilo'), const {});
      expect(r.map((i) => i.id), [3]);
    });

    test('filtro rápido de stock bajo y sin stock', () {
      expect(
        filtrarInsumos(insumos, const FiltroInventario(rapido: FiltroRapido.stockBajo), const {}).map((i) => i.id),
        [1],
      );
      expect(
        filtrarInsumos(insumos, const FiltroInventario(rapido: FiltroRapido.sinStock), const {}).map((i) => i.id),
        [2],
      );
    });

    test('"en riesgo" usa los niveles ALTO y CRÍTICO de la IA', () {
      final riesgos = {1: NivelRiesgo.medio, 2: NivelRiesgo.critico, 3: NivelRiesgo.alto};
      final r = filtrarInsumos(insumos, const FiltroInventario(rapido: FiltroRapido.enRiesgo), riesgos);
      expect(r.map((i) => i.id), [2, 3]);
    });
  });

  group('lectura de datos del backend', () {
    test('insumo en camelCase', () {
      final insumo = insumoDesdeJson({
        'id': 48,
        'nombre': 'Elástico',
        'stock': 79,
        'unidadMedida': 'Centímetros',
        'tipo': 'Accesorio',
        'stockMinimo': 200,
        'activo': true,
        'stockBajo': true,
        'updatedAt': '2026-05-13 13:18:23',
      });
      expect(insumo.estado, EstadoStock.stockBajo);
      expect(insumo.actualizadoEn, DateTime(2026, 5, 13, 13, 18, 23));
    });

    test('insumo sin tipo se agrupa en "Otros"', () {
      expect(insumoDesdeJson({'id': 1, 'nombre': 'x', 'tipo': '  '}).tipo, 'Otros');
    });

    test('predicción en snake_case (como la reenvía el backend)', () {
      final p = prediccionDesdeJson({
        'insumo_id': 48,
        'prophet': {
          'dias_hasta_stock_minimo': 1,
          'consumo_diario_promedio': 2.5,
          'fecha_alerta_estimada': '2026-10-09',
          'confianza': 0.95,
        },
        'xgboost': {
          'nivel_riesgo': 'ALTO',
          'probabilidades': {'BAJO': 0.1, 'ALTO': 0.9},
          'modelo_entrenado': true,
        },
        'features': {'consumo_7d': 14, 'consumo_30d': 60, 'consumo_90d': 150},
        'alerta': true,
        'mensaje': 'Stock bajo',
        'recomendacion': 'Realizar pedido esta semana.',
      });
      expect(p.insumoId, 48);
      expect(p.nivelRiesgo, NivelRiesgo.alto);
      expect(p.probabilidades[NivelRiesgo.alto], 0.9);
      expect(p.diasHastaMinimo, 1);
      expect(p.fechaAlerta, DateTime(2026, 10, 9));
      expect(p.hayConsumo, isTrue);
      expect(p.consumo30Dias, 60);
    });

    test('un nivel de riesgo desconocido no rompe la app', () {
      expect(NivelRiesgo.desdeCodigo('RARO'), NivelRiesgo.desconocido);
      expect(NivelRiesgo.desdeCodigo('crítico'), NivelRiesgo.critico);
    });
  });

  group('formatos en español', () {
    test('moneda colombiana con el símbolo adelante', () => expect(Formatos.moneda(28000), r'$ 28.000'));

    test('números con separador de miles', () {
      expect(Formatos.numero(1234), '1.234');
      expect(Formatos.numero(2.5), '2,5');
    });

    test('tiempo relativo', () {
      final ahora = DateTime(2026, 10, 8, 12);
      expect(Formatos.haceCuanto(ahora.subtract(const Duration(minutes: 5)), ahora: ahora), 'hace 5 min');
      expect(Formatos.haceCuanto(ahora.subtract(const Duration(days: 1)), ahora: ahora), 'ayer');
      expect(Formatos.haceCuanto(ahora.subtract(const Duration(days: 3)), ahora: ahora), 'hace 3 días');
    });
  });
}
