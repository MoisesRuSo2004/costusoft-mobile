import 'package:costusoft_mobile/nucleo/errores/fallo.dart';
import 'package:costusoft_mobile/nucleo/red/mapeador_errores.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _respuestaConError(int codigo, [Object? datos]) {
  final opciones = RequestOptions(path: '/api/x');
  return DioException(
    requestOptions: opciones,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: opciones, statusCode: codigo, data: datos),
  );
}

void main() {
  group('mapearErrorDeRed', () {
    test('error de conexión → FalloRed', () {
      final error = DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError);
      expect(mapearErrorDeRed(error), isA<FalloRed>());
    });

    test('tiempo de respuesta agotado → FalloTiempoAgotado', () {
      final error = DioException(requestOptions: RequestOptions(), type: DioExceptionType.receiveTimeout);
      expect(mapearErrorDeRed(error), isA<FalloTiempoAgotado>());
    });

    test('400 usa el mensaje de la RespuestaApi del backend', () {
      final fallo = mapearErrorDeRed(
        _respuestaConError(400, {'success': false, 'message': 'El usuario es obligatorio'}),
      );
      expect(fallo, isA<FalloValidacion>());
      expect(fallo.mensaje, 'El usuario es obligatorio');
    });

    test('400 conserva los errores por campo', () {
      final fallo = mapearErrorDeRed(
        _respuestaConError(400, {
          'success': false,
          'message': 'Datos inválidos',
          'data': {'password': 'muy corta'},
        }),
      );
      expect((fallo as FalloValidacion).erroresPorCampo, {'password': 'muy corta'});
    });

    test('401 → FalloNoAutorizado', () {
      expect(mapearErrorDeRed(_respuestaConError(401)), isA<FalloNoAutorizado>());
    });

    test('403 → FalloPermiso', () {
      expect(mapearErrorDeRed(_respuestaConError(403)), isA<FalloPermiso>());
    });

    test('503 → FalloServicioIniciando (un FalloServidor con el código)', () {
      final fallo = mapearErrorDeRed(_respuestaConError(503));
      expect(fallo, isA<FalloServicioIniciando>());
      expect((fallo as FalloServidor).codigoEstado, 503);
    });

    test('un error que no es de Dio → FalloInesperado', () {
      expect(mapearErrorDeRed(StateError('x')), isA<FalloInesperado>());
    });
  });
}
