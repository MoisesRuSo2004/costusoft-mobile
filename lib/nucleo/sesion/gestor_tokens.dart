import 'dart:async';

import 'package:jwt_decoder/jwt_decoder.dart';

import '../utilidades/registro_app.dart';
import 'almacen_tokens.dart';
import 'tokens_sesion.dart';

/// El backend rechazó el token de renovación (vencido, inválido o cuenta
/// desactivada): la sesión terminó y hay que volver a iniciar sesión.
class RenovacionRechazada implements Exception {
  const RenovacionRechazada();
}

/// Pide al backend un nuevo par de tokens. Lanza [RenovacionRechazada] si el
/// backend lo rechaza; cualquier otra excepción se trata como problema de red.
typedef RenovadorTokens = Future<TokensSesion> Function(String tokenRenovacion);

/// Dueño único de los tokens de la sesión.
///
/// - Los mantiene en memoria y en el [AlmacenTokens] cifrado.
/// - Renueva el token de acceso antes de que venza.
/// - Si varias peticiones necesitan renovar a la vez, hace **una sola**
///   llamada al backend y todas esperan el mismo resultado.
/// - Avisa por [sesionExpirada] cuando la sesión ya no se puede renovar.
class GestorTokens {
  GestorTokens({
    required this._almacen,
    required this._renovador,
    this._margenVencimiento = const Duration(seconds: 30),
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final AlmacenTokens _almacen;
  final RenovadorTokens _renovador;
  final Duration _margenVencimiento;
  final DateTime Function() _reloj;
  final _sesionExpirada = StreamController<void>.broadcast();

  TokensSesion? _tokens;
  Completer<String?>? _renovacionEnCurso;

  /// Emite cuando la sesión terminó porque el backend rechazó la renovación.
  Stream<void> get sesionExpirada => _sesionExpirada.stream;

  bool get tieneSesion => _tokens != null;

  String? get tokenAcceso => _tokens?.acceso;

  /// Carga los tokens guardados (al abrir la app).
  Future<void> cargar() async => _tokens = await _almacen.leer();

  Future<void> guardar(TokensSesion tokens) async {
    _tokens = tokens;
    await _almacen.guardar(tokens);
  }

  Future<void> limpiar() async {
    _tokens = null;
    await _almacen.borrar();
  }

  /// Token de acceso listo para usar: si está por vencer, lo renueva primero.
  Future<String?> tokenAccesoVigente() async {
    final tokens = _tokens;
    if (tokens == null) return null;
    return _estaPorVencer(tokens.acceso) ? renovar() : tokens.acceso;
  }

  /// Renueva la sesión. Las llamadas simultáneas comparten la misma petición.
  /// Devuelve el nuevo token de acceso, o `null` si no se pudo renovar.
  Future<String?> renovar() {
    final enCurso = _renovacionEnCurso;
    if (enCurso != null) return enCurso.future;

    final completer = Completer<String?>();
    _renovacionEnCurso = completer;
    unawaited(_ejecutarRenovacion().then(completer.complete).whenComplete(() => _renovacionEnCurso = null));
    return completer.future;
  }

  Future<String?> _ejecutarRenovacion() async {
    final tokens = _tokens;
    if (tokens == null) return null;
    try {
      final nuevos = await _renovador(tokens.renovacion);
      await guardar(nuevos);
      return nuevos.acceso;
    } on RenovacionRechazada {
      await limpiar();
      _sesionExpirada.add(null);
      return null;
    } on Object catch (error) {
      // Falla de red: se conservan los tokens para reintentar más tarde.
      registroApp.w('No se pudo renovar la sesión: $error');
      return null;
    }
  }

  bool _estaPorVencer(String jwt) {
    try {
      final vence = JwtDecoder.getExpirationDate(jwt);
      return vence.isBefore(_reloj().add(_margenVencimiento));
    } on Object {
      return true; // Token ilegible: mejor intentar renovarlo.
    }
  }

  Future<void> cerrar() => _sesionExpirada.close();
}
