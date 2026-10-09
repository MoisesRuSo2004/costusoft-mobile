import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'tokens_sesion.dart';

/// Dónde se guardan los tokens entre aperturas de la app.
abstract interface class AlmacenTokens {
  Future<TokensSesion?> leer();
  Future<void> guardar(TokensSesion tokens);
  Future<void> borrar();
}

/// Almacenamiento cifrado: Keystore en Android, Keychain en iOS y
/// WebCrypto + localStorage en el navegador.
class AlmacenTokensSeguro implements AlmacenTokens {
  AlmacenTokensSeguro([FlutterSecureStorage? almacen]) : _almacen = almacen ?? const FlutterSecureStorage();

  static const _claveAcceso = 'cs_token_acceso';
  static const _claveRenovacion = 'cs_token_renovacion';

  final FlutterSecureStorage _almacen;

  @override
  Future<TokensSesion?> leer() async {
    final acceso = await _almacen.read(key: _claveAcceso);
    final renovacion = await _almacen.read(key: _claveRenovacion);
    if (acceso == null || renovacion == null) return null;
    return TokensSesion(acceso: acceso, renovacion: renovacion);
  }

  @override
  Future<void> guardar(TokensSesion tokens) async {
    await _almacen.write(key: _claveAcceso, value: tokens.acceso);
    await _almacen.write(key: _claveRenovacion, value: tokens.renovacion);
  }

  @override
  Future<void> borrar() async {
    await _almacen.delete(key: _claveAcceso);
    await _almacen.delete(key: _claveRenovacion);
  }
}
