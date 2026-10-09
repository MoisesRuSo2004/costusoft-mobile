import 'package:dio/dio.dart';

import '../../inventario/dominio/prediccion_insumo.dart';
import '../dominio/resumen_tablero.dart';

/// Llamadas de `/api/dashboard` y conteos de `/api/pedidos`.
class FuenteRemotaTablero {
  const FuenteRemotaTablero(this._cliente);

  final Dio _cliente;

  Future<ResumenTablero> obtenerResumen() async {
    final r = await _cliente.get<Map<String, dynamic>>('/api/dashboard/resumen');
    return resumenDesdeJson(r.data!['data'] as Map<String, dynamic>);
  }

  /// El backend no tiene un endpoint de conteos: se pide 1 pedido por estado
  /// y se lee `totalElements` (todas las consultas van en paralelo).
  Future<ConteoPedidos> contarPedidos() async {
    const estados = EstadoPedido.values;
    final totales = await Future.wait([
      for (final estado in estados)
        _cliente
            .get<Map<String, dynamic>>(
              '/api/pedidos/estado',
              queryParameters: {'estado': estado.codigo, 'page': 0, 'size': 1},
            )
            .then((r) => ((r.data?['data'] as Map<String, dynamic>?)?['totalElements'] as num?)?.toInt() ?? 0),
    ]);
    return ConteoPedidos({for (var i = 0; i < estados.length; i++) estados[i]: totales[i]});
  }
}

int _entero(Object? valor) => (valor as num?)?.toInt() ?? 0;

ResumenTablero resumenDesdeJson(Map<String, dynamic> json) {
  final entradas = json['entradasPorMes'] as Map<String, dynamic>? ?? const {};
  final salidas = json['salidasPorMes'] as Map<String, dynamic>? ?? const {};
  final meses = {...entradas.keys, ...salidas.keys}.toList()..sort();

  return ResumenTablero(
    totalInsumos: _entero(json['totalInsumos']),
    totalEntradas: _entero(json['totalEntradas']),
    totalSalidas: _entero(json['totalSalidas']),
    totalColegios: _entero(json['totalColegios']),
    totalUniformes: _entero(json['totalUniformes']),
    totalProveedores: _entero(json['totalProveedores']),
    totalUsuarios: _entero(json['totalUsuarios']),
    insumosConStockBajo: _entero(json['insumosConStockBajo']),
    insumosSinStock: _entero(json['insumosConStockCero']),
    alertas: [
      for (final a in (json['alertasStock'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        AlertaStock(
          insumoId: _entero(a['id']),
          nombre: a['nombre'] as String? ?? '',
          stockActual: _entero(a['stockActual']),
          stockMinimo: _entero(a['stockMinimo']),
          unidad: a['unidadMedida'] as String? ?? '',
          nivelRiesgo: NivelRiesgo.desdeCodigo(a['nivelRiesgo'] as String?),
        ),
    ],
    movimientosPorMes: [
      for (final mes in meses)
        MovimientosDelMes(
          // "2026-04" → 1 de abril de 2026
          mes: DateTime.tryParse('$mes-01') ?? DateTime(2000),
          entradas: _entero(entradas[mes]),
          salidas: _entero(salidas[mes]),
        ),
    ],
    ultimosMovimientos: [
      for (final m in (json['ultimosMovimientos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        MovimientoReciente(
          tipo: (m['tipo'] as String?)?.toUpperCase() == 'ENTRADA' ? TipoMovimiento.entrada : TipoMovimiento.salida,
          descripcion: (m['descripcion'] as String?)?.trim().isNotEmpty == true
              ? (m['descripcion'] as String).trim()
              : 'Sin descripción',
          totalItems: _entero(m['totalItems']),
          fecha: DateTime.tryParse(m['fecha'] as String? ?? ''),
        ),
    ],
  );
}
