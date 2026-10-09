import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Recuérdame": guarda el nombre de usuario (nunca la contraseña) para
/// precargarlo la próxima vez, igual que hace la plataforma web.
class PreferenciasIngreso {
  const PreferenciasIngreso(this._preferencias);

  static const _claveUsuario = 'cs_usuario_recordado';

  final SharedPreferencesAsync _preferencias;

  Future<String?> usuarioRecordado() => _preferencias.getString(_claveUsuario);

  Future<void> recordarUsuario(String nombreUsuario) => _preferencias.setString(_claveUsuario, nombreUsuario.trim());

  Future<void> olvidarUsuario() => _preferencias.remove(_claveUsuario);
}

final proveedorPreferenciasIngreso = Provider<PreferenciasIngreso>(
  (ref) => PreferenciasIngreso(SharedPreferencesAsync()),
);

/// Usuario recordado al abrir la pantalla de ingreso.
final proveedorUsuarioRecordado = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(proveedorPreferenciasIngreso).usuarioRecordado(),
);
