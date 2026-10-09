import 'package:costusoft_mobile/nucleo/red/respuesta_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RespuestaApi decodifica el envoltorio del backend', () {
    final json = {
      'success': true,
      'message': 'Login exitoso',
      'data': {'username': 'admin'},
      'timestamp': '2026-10-08T10:00:00',
    };
    final respuesta = RespuestaApi.desdeJson(json, (d) => (d! as Map<String, dynamic>)['username'] as String);
    expect(respuesta.exito, isTrue);
    expect(respuesta.mensaje, 'Login exitoso');
    expect(respuesta.datos, 'admin');
    expect(respuesta.fecha, DateTime(2026, 10, 8, 10));
  });

  test('RespuestaApi tolera datos nulos', () {
    final respuesta = RespuestaApi<String>.desdeJson({'success': true, 'message': 'OK'}, (d) => d! as String);
    expect(respuesta.datos, isNull);
  });

  test('PaginaApi decodifica el PageDTO del backend', () {
    final json = {
      'content': [
        {'id': 1},
        {'id': 2},
      ],
      'number': 0,
      'size': 2,
      'totalElements': 5,
      'totalPages': 3,
      'first': true,
      'last': false,
    };
    final pagina = PaginaApi.desdeJson(json, (e) => e['id'] as int);
    expect(pagina.contenido, [1, 2]);
    expect(pagina.totalElementos, 5);
    expect(pagina.hayMasPaginas, isTrue);
  });
}
