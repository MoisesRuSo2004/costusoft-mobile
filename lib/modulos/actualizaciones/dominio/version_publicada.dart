/// Una versión de la app publicada en GitHub Releases.
class VersionPublicada {
  const VersionPublicada({
    required this.version,
    required this.notas,
    required this.urlApk,
    required this.tamanoBytes,
    this.sha256,
  });

  /// "1.1.0" (sin la "v" de la etiqueta).
  final String version;

  /// Texto del release: qué trae la versión.
  final String notas;
  final String urlApk;
  final int tamanoBytes;

  /// Huella del APK que publica GitHub, para verificar la descarga.
  final String? sha256;
}

/// Compara versiones "mayor.menor.parche" (ignora "v" y "+build").
/// Devuelve negativo si [a] es anterior a [b], 0 si son iguales.
int compararVersiones(String a, String b) {
  List<int> partes(String v) {
    final limpia = v.trim().replaceFirst(RegExp('^[vV]'), '').split('+').first.split('-').first;
    final numeros = limpia.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (numeros.length < 3) {
      numeros.add(0);
    }
    return numeros;
  }

  final pa = partes(a);
  final pb = partes(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
  }
  return 0;
}
