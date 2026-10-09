import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:costusoft_mobile/nucleo/errores/fallo.dart';
import 'package:costusoft_mobile/nucleo/red/mapeador_errores.dart';
import 'package:costusoft_mobile/nucleo/sin_conexion/bandeja_salida.dart';
import 'package:costusoft_mobile/nucleo/sin_conexion/copia_local.dart';
import 'package:costusoft_mobile/nucleo/sin_conexion/interceptor_sin_conexion.dart';
import 'package:costusoft_mobile/nucleo/sin_conexion/sincronizacion.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Dobles en memoria ─────────────────────────────────────────────────────

class _CopiaEnMemoria implements CopiaLocal {
  final datos = <String, RespuestaGuardada>{};

  @override
  Future<void> guardar(String clave, String cuerpo) async =>
      datos[clave] = RespuestaGuardada(cuerpo: cuerpo, guardadaEn: DateTime(2026, 10, 8, 9));

  @override
  Future<RespuestaGuardada?> leer(String clave) async => datos[clave];

  @override
  Future<int?> leerDueno() async => null;

  @override
  Future<void> asignarDueno(int usuarioId) async {}

  @override
  Future<void> podar({Duration antiguedad = const Duration(days: 14), int maximo = 400}) async {}

  @override
  Future<void> limpiar() async => datos.clear();
}

class _BandejaEnMemoria implements BandejaSalida {
  final acciones = <AccionPendiente>[];
  var _siguienteId = 1;

  @override
  Future<void> agregar(SolicitudPendiente solicitud) async => acciones.add(
    AccionPendiente(
      id: _siguienteId++,
      solicitud: solicitud,
      estado: EstadoAccion.pendiente,
      intentos: 0,
      creadaEn: DateTime.now(),
    ),
  );

  @override
  Future<List<AccionPendiente>> listarPendientes() async =>
      acciones.where((a) => a.estado == EstadoAccion.pendiente).toList();

  @override
  Future<void> eliminar(int id) async => acciones.removeWhere((a) => a.id == id);

  AccionPendiente _con(int id, {EstadoAccion? estado, String? error, bool sumarIntento = false}) {
    final a = acciones.firstWhere((x) => x.id == id);
    return AccionPendiente(
      id: a.id,
      solicitud: a.solicitud,
      estado: estado ?? a.estado,
      intentos: a.intentos + (sumarIntento ? 1 : 0),
      creadaEn: a.creadaEn,
      ultimoError: error ?? a.ultimoError,
    );
  }

  void _reemplazar(AccionPendiente nueva) => acciones[acciones.indexWhere((a) => a.id == nueva.id)] = nueva;

  @override
  Future<void> marcarConflicto(int id, String mensaje) async =>
      _reemplazar(_con(id, estado: EstadoAccion.conflicto, error: mensaje));

  @override
  Future<void> registrarIntento(int id, String mensaje) async =>
      _reemplazar(_con(id, error: mensaje, sumarIntento: true));

  @override
  Stream<List<AccionPendiente>> observar() => Stream.value(acciones);

  @override
  Future<void> limpiar() async => acciones.clear();
}

SolicitudPendiente _solicitud(String recurso) => SolicitudPendiente(
  metodo: 'PATCH',
  ruta: '/api/$recurso/confirmar',
  recurso: recurso,
  descripcion: 'Confirmar $recurso',
);

DioException _sinRed(String ruta) => DioException(
  requestOptions: RequestOptions(path: ruta),
  type: DioExceptionType.connectionError,
);

DioException _respuesta(String ruta, int codigo, String mensaje) {
  final opciones = RequestOptions(path: ruta);
  return DioException(
    requestOptions: opciones,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: opciones, statusCode: codigo, data: {'message': mensaje}),
  );
}

/// Adaptador HTTP de prueba: responde según [responder] o simula la caída.
class _AdaptadorPrueba implements HttpClientAdapter {
  _AdaptadorPrueba(this.responder);

  ResponseBody Function(RequestOptions opciones) responder;
  var sinRed = false;

  @override
  Future<ResponseBody> fetch(RequestOptions opciones, Stream<Uint8List>? cuerpo, Future<void>? cancelar) async {
    if (sinRed) throw DioException(requestOptions: opciones, type: DioExceptionType.connectionError);
    return responder(opciones);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object datos, {int codigo = 200}) => ResponseBody.fromString(
  jsonEncode(datos),
  codigo,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test('una conexión rechazada se marca como "no enviada" (se puede reenviar)', () {
    final fallo = mapearErrorDeRed(_sinRed('/x'));
    expect(fallo, isA<FalloRed>().having((f) => f.noSeEnvio, 'noSeEnvio', isTrue));
    final tiempo = mapearErrorDeRed(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    expect(tiempo, isA<FalloRed>().having((f) => f.noSeEnvio, 'noSeEnvio', isFalse));
  });

  group('Sincronizador', () {
    late _BandejaEnMemoria bandeja;
    setUp(() async {
      bandeja = _BandejaEnMemoria();
      for (final r in ['entradas/1', 'salidas/2', 'entradas/3']) {
        await bandeja.agregar(_solicitud(r));
      }
    });

    test('envía en orden y vacía la bandeja', () async {
      final enviadas = <String>[];
      final resumen = await Sincronizador(bandeja: bandeja, enviar: (s) async => enviadas.add(s.recurso)).sincronizar();
      expect(enviadas, ['entradas/1', 'salidas/2', 'entradas/3']);
      expect(resumen.aplicadas, hasLength(3));
      expect(bandeja.acciones, isEmpty);
    });

    test('un rechazo del servidor queda como conflicto y se sigue con las demás', () async {
      final resumen = await Sincronizador(
        bandeja: bandeja,
        enviar: (s) async {
          if (s.recurso == 'salidas/2') throw _respuesta(s.ruta, 400, 'La salida ya fue confirmada.');
        },
      ).sincronizar();
      expect(resumen.aplicadas, hasLength(2));
      expect(resumen.conflictos, 1);
      expect(bandeja.acciones.single.estado, EstadoAccion.conflicto);
      expect(bandeja.acciones.single.ultimoError, 'La salida ya fue confirmada.');
    });

    test('sin red se detiene sin saltarse el orden', () async {
      final enviadas = <String>[];
      final resumen = await Sincronizador(
        bandeja: bandeja,
        enviar: (s) async {
          if (s.recurso == 'salidas/2') throw _sinRed(s.ruta);
          enviadas.add(s.recurso);
        },
      ).sincronizar();
      expect(enviadas, ['entradas/1']); // entradas/3 no se envía antes que salidas/2
      expect(resumen.interrumpida, isTrue);
      expect(bandeja.acciones.map((a) => a.solicitud.recurso), ['salidas/2', 'entradas/3']);
      expect(bandeja.acciones.first.intentos, 1);
      expect(bandeja.acciones.first.estado, EstadoAccion.pendiente);
    });

    test('un error 5xx se reintenta más tarde', () async {
      final resumen = await Sincronizador(
        bandeja: bandeja,
        enviar: (s) async => throw _respuesta(s.ruta, 503, 'Servidor no disponible'),
      ).sincronizar();
      expect(resumen.interrumpida, isTrue);
      expect(bandeja.acciones, hasLength(3));
      expect(bandeja.acciones.every((a) => a.estado == EstadoAccion.pendiente), isTrue);
    });
  });

  group('InterceptorSinConexion', () {
    late _CopiaEnMemoria copia;
    late _AdaptadorPrueba adaptador;
    late Dio dio;
    var respuestas = 0;
    var perdidas = 0;
    DateTime? copiaUsada;

    setUp(() {
      respuestas = 0;
      perdidas = 0;
      copiaUsada = null;
      copia = _CopiaEnMemoria();
      adaptador = _AdaptadorPrueba((o) => _json({'data': o.path}));
      dio = Dio(BaseOptions(baseUrl: 'http://api'))
        ..httpClientAdapter = adaptador
        ..interceptors.add(
          InterceptorSinConexion(
            copia: copia,
            alResponderServidor: () => respuestas++,
            alPerderConexion: () => perdidas++,
            alUsarCopia: (fecha) => copiaUsada = fecha,
          ),
        );
    });

    Future<void> esperarGuardado() => Future<void>.delayed(Duration.zero);

    test('guarda cada GET y lo sirve desde la copia sin conexión', () async {
      await dio.get<dynamic>('/api/insumos', queryParameters: {'page': 0});
      await esperarGuardado();
      expect(copia.datos.keys.single, 'GET http://api/api/insumos?page=0');
      expect(respuestas, 1);

      adaptador.sinRed = true;
      final r = await dio.get<dynamic>('/api/insumos', queryParameters: {'page': 0});
      expect(r.data, {'data': '/api/insumos'});
      expect(r.extra[claveDesdeCopia], isTrue);
      expect(perdidas, 1);
      expect(copiaUsada, DateTime(2026, 10, 8, 9));
    });

    test('sin copia guardada el error llega al repositorio', () async {
      adaptador.sinRed = true;
      await expectLater(dio.get<dynamic>('/api/pedidos'), throwsA(isA<DioException>()));
      expect(perdidas, 1);
    });

    test('los cambios (PATCH/POST) nunca se responden con la copia', () async {
      await dio.get<dynamic>('/api/entradas/1');
      await esperarGuardado();
      adaptador.sinRed = true;
      await expectLater(dio.patch<dynamic>('/api/entradas/1'), throwsA(isA<DioException>()));
    });

    test('un error del servidor cuenta como "en línea" y no usa la copia', () async {
      adaptador.responder = (_) => _json({'message': 'No encontrado'}, codigo: 404);
      await expectLater(dio.get<dynamic>('/api/insumos/999'), throwsA(isA<DioException>()));
      expect(respuestas, 1);
      expect(copia.datos, isEmpty);
    });

    test('con sinCopia no se guarda', () async {
      await dio.get<dynamic>('/api/ia/briefing', options: Options(extra: {claveSinCopia: true}));
      await esperarGuardado();
      expect(copia.datos, isEmpty);
    });
  });

  test('EstadoSincronizacion cuenta pendientes, conflictos y recursos en cola', () {
    final estado = EstadoSincronizacion(
      acciones: [
        AccionPendiente(
          id: 1,
          solicitud: _solicitud('entradas/1'),
          estado: EstadoAccion.pendiente,
          intentos: 0,
          creadaEn: DateTime(2026),
        ),
        AccionPendiente(
          id: 2,
          solicitud: _solicitud('pedidos/9'),
          estado: EstadoAccion.conflicto,
          intentos: 0,
          creadaEn: DateTime(2026),
        ),
      ],
    );
    expect(estado.pendientes, 1);
    expect(estado.conflictos, 1);
    expect(estado.recursosEnCola, {'entradas/1'});
  });
}
