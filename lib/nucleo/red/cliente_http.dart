import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../configuracion/configuracion_app.dart';
import '../sesion/almacen_tokens.dart';
import '../sesion/gestor_tokens.dart';
import '../sesion/renovador_backend.dart';
import '../sin_conexion/almacen_local.dart';
import '../sin_conexion/estado_red.dart';
import '../sin_conexion/interceptor_sin_conexion.dart';
import '../utilidades/registro_app.dart';
import 'interceptor_autenticacion.dart';

final proveedorConfiguracion = Provider<ConfiguracionApp>((ref) => ConfiguracionApp.desdeEntorno());

/// Cliente sin autenticación: inicio de sesión, renovación y verificación
/// del servidor. También se usa para reintentar peticiones tras renovar.
final proveedorClientePublico = Provider<Dio>((ref) {
  final cliente = _crearCliente(ref.watch(proveedorConfiguracion));
  ref.onDispose(cliente.close);
  return cliente;
});

final proveedorAlmacenTokens = Provider<AlmacenTokens>((ref) => AlmacenTokensSeguro());

final proveedorGestorTokens = Provider<GestorTokens>((ref) {
  final gestor = GestorTokens(
    almacen: ref.watch(proveedorAlmacenTokens),
    renovador: renovadorConBackend(ref.watch(proveedorClientePublico)),
  );
  ref.onDispose(gestor.cerrar);
  return gestor;
});

/// Cliente autenticado hacia el backend Spring Boot (la fachada de toda la app).
/// Agrega el JWT, renueva la sesión automáticamente y, sin conexión, responde
/// las consultas con la copia local.
final proveedorClienteHttp = Provider<Dio>((ref) {
  final cliente = _crearCliente(ref.watch(proveedorConfiguracion));
  cliente.interceptors.insert(
    0,
    InterceptorAutenticacion(
      gestor: ref.watch(proveedorGestorTokens),
      clienteReintento: ref.watch(proveedorClientePublico),
    ),
  );
  cliente.interceptors.add(
    InterceptorSinConexion(
      copia: ref.watch(proveedorCopiaLocal),
      alResponderServidor: () => ref.read(proveedorRed.notifier).marcarEnLinea(),
      alPerderConexion: () => ref.read(proveedorRed.notifier).marcarSinConexion(),
      alUsarCopia: (guardadaEn) => ref.read(proveedorRed.notifier).registrarCopia(guardadaEn),
    ),
  );
  ref.onDispose(cliente.close);
  return cliente;
});

Dio _crearCliente(ConfiguracionApp configuracion) {
  final cliente = Dio(
    BaseOptions(
      baseUrl: configuracion.urlBaseApi,
      connectTimeout: configuracion.tiempoMaximoConexion,
      receiveTimeout: configuracion.tiempoMaximoRespuesta,
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    ),
  );
  cliente.interceptors.add(_InterceptorTiempoMaximo());
  if (!configuracion.esProduccion) {
    cliente.interceptors.add(_InterceptorDeRegistro());
  }
  return cliente;
}

/// Clave de `Options.extra` para dar más tiempo a una petición lenta:
/// `Options(extra: {claveTiempoMaximo: Duration(seconds: 90)})`.
const claveTiempoMaximo = 'tiempoMaximo';

/// Aplica [claveTiempoMaximo] a los dos límites de Dio (en web, el de conexión
/// también cubre la espera de la respuesta).
class _InterceptorTiempoMaximo extends Interceptor {
  @override
  void onRequest(RequestOptions opciones, RequestInterceptorHandler manejador) {
    final tiempo = opciones.extra[claveTiempoMaximo];
    if (tiempo is Duration) {
      opciones
        ..connectTimeout = tiempo
        ..receiveTimeout = tiempo;
    }
    manejador.next(opciones);
  }
}

/// Escribe en consola cada petición, su respuesta y cuánto tardó.
class _InterceptorDeRegistro extends Interceptor {
  @override
  void onRequest(RequestOptions opciones, RequestInterceptorHandler manejador) {
    opciones.extra['inicio'] = DateTime.now();
    registroApp.d('→ ${opciones.method} ${opciones.uri}');
    manejador.next(opciones);
  }

  @override
  void onResponse(Response<dynamic> respuesta, ResponseInterceptorHandler manejador) {
    registroApp.d('← ${respuesta.statusCode} ${respuesta.requestOptions.uri} ${_duracion(respuesta.requestOptions)}');
    manejador.next(respuesta);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler manejador) {
    registroApp.w(
      '✗ ${error.response?.statusCode ?? error.type.name} ${error.requestOptions.uri} ${_duracion(error.requestOptions)}',
    );
    manejador.next(error);
  }

  String _duracion(RequestOptions opciones) {
    final inicio = opciones.extra['inicio'];
    if (inicio is! DateTime) return '';
    return '(${DateTime.now().difference(inicio).inMilliseconds} ms)';
  }
}
