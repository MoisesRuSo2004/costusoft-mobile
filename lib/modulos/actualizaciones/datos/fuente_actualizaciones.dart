import 'package:dio/dio.dart';

import '../dominio/version_publicada.dart';

/// Lee la última versión publicada en GitHub Releases (repositorio público,
/// sin credenciales). Cada release lleva el APK firmado como archivo adjunto.
class FuenteActualizaciones {
  FuenteActualizaciones([Dio? cliente])
    : _cliente =
          cliente ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/vnd.github+json'},
            ),
          );

  static const repositorio = 'MoisesRuSo2004/costusoft-mobile';
  static const _urlUltima = 'https://api.github.com/repos/$repositorio/releases/latest';

  final Dio _cliente;

  /// `null` si aún no hay ninguna versión publicada o no trae APK.
  Future<VersionPublicada?> ultima() async {
    try {
      final respuesta = await _cliente.get<Map<String, dynamic>>(_urlUltima);
      return versionDesdeJson(respuesta.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // sin releases todavía
      rethrow;
    }
  }
}

/// Convierte la respuesta de `releases/latest` (separado para probarlo).
VersionPublicada? versionDesdeJson(Map<String, dynamic> json) {
  final etiqueta = json['tag_name'] as String?;
  final archivos = (json['assets'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  final apk = archivos.where((a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.apk')).firstOrNull;
  if (etiqueta == null || apk == null || json['draft'] == true || json['prerelease'] == true) return null;

  final huella = apk['digest'] as String?; // "sha256:…"
  return VersionPublicada(
    version: etiqueta.replaceFirst(RegExp('^[vV]'), ''),
    notas: (json['body'] as String? ?? '').trim(),
    urlApk: apk['browser_download_url'] as String,
    tamanoBytes: (apk['size'] as num?)?.toInt() ?? 0,
    sha256: huella != null && huella.startsWith('sha256:') ? huella.substring(7) : null,
  );
}
