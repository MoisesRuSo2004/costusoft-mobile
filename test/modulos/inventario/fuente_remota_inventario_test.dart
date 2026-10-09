import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:costusoft_mobile/modulos/inventario/datos/fuente_remota_inventario.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend simulado de `/api/insumos` con [total] insumos paginados.
/// Registra cuántas peticiones están en curso a la vez.
class _BackendSimulado implements HttpClientAdapter {
  _BackendSimulado(this.total);

  final int total;
  final paginasPedidas = <int>[];
  int enCurso = 0;
  int maximoSimultaneas = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions opciones, Stream<Uint8List>? cuerpo, Future<void>? cancelar) async {
    final pagina = int.parse(opciones.queryParameters['page'].toString());
    final tamano = int.parse(opciones.queryParameters['size'].toString());
    paginasPedidas.add(pagina);
    enCurso++;
    maximoSimultaneas = enCurso > maximoSimultaneas ? enCurso : maximoSimultaneas;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    enCurso--;

    final desde = pagina * tamano;
    final hasta = (desde + tamano).clamp(0, total);
    final totalPaginas = (total / tamano).ceil();
    final json = {
      'success': true,
      'message': 'OK',
      'data': {
        'content': [
          for (var id = desde; id < hasta; id++) {'id': id, 'nombre': 'Insumo $id', 'stock': 5, 'stockMinimo': 1},
        ],
        'number': pagina,
        'size': tamano,
        'totalElements': total,
        'totalPages': totalPaginas,
        'first': pagina == 0,
        'last': pagina >= totalPaginas - 1,
      },
    };
    return ResponseBody.fromString(
      jsonEncode(json),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('trae el catálogo completo: primera página y luego el resto en paralelo', () async {
    final backend = _BackendSimulado(250);
    final cliente = Dio(BaseOptions(baseUrl: 'http://backend'))..httpClientAdapter = backend;

    final insumos = await FuenteRemotaInventario(cliente).listarInsumos();

    expect(insumos, hasLength(250));
    expect(insumos.map((i) => i.id), List.generate(250, (i) => i), reason: 'conserva el orden');
    expect(backend.paginasPedidas.first, 0);
    expect(backend.paginasPedidas.toSet(), {0, 1, 2});
    expect(backend.maximoSimultaneas, 2, reason: 'las páginas 1 y 2 se piden a la vez');
  });

  test('con una sola página hace una sola petición', () async {
    final backend = _BackendSimulado(55);
    final cliente = Dio(BaseOptions(baseUrl: 'http://backend'))..httpClientAdapter = backend;

    final insumos = await FuenteRemotaInventario(cliente).listarInsumos();

    expect(insumos, hasLength(55));
    expect(backend.paginasPedidas, [0]);
  });
}
