import 'package:costusoft_mobile/modulos/actualizaciones/datos/fuente_actualizaciones.dart';
import 'package:costusoft_mobile/modulos/actualizaciones/dominio/version_publicada.dart';
import 'package:costusoft_mobile/modulos/actualizaciones/presentacion/controlador_actualizacion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Respuesta real (recortada) de `GET /repos/{repo}/releases/latest`.
Map<String, dynamic> _release({String etiqueta = 'v1.1.0', bool conApk = true}) => {
  'tag_name': etiqueta,
  'draft': false,
  'prerelease': false,
  'body': '- Avisos como notificación del sistema\n- Cierre de sesión por inactividad',
  'assets': [
    {'name': 'notas.txt', 'browser_download_url': 'https://github.com/x/notas.txt', 'size': 10},
    if (conApk)
      {
        'name': 'costusoft-1.1.0.apk',
        'browser_download_url': 'https://github.com/MoisesRuSo2004/costusoft-mobile/releases/download/v1.1.0/costusoft-1.1.0.apk',
        'size': 52428800,
        'digest': 'sha256:abc123',
      },
  ],
};

class _FuenteFalsa extends FuenteActualizaciones {
  _FuenteFalsa(this.respuesta);

  final VersionPublicada? respuesta;
  int consultas = 0;

  @override
  Future<VersionPublicada?> ultima() async {
    consultas++;
    return respuesta;
  }
}

void main() {
  group('compararVersiones', () {
    test('ordena por mayor, menor y parche', () {
      expect(compararVersiones('1.1.0', '1.0.0'), greaterThan(0));
      expect(compararVersiones('1.0.9', '1.1.0'), lessThan(0));
      expect(compararVersiones('1.10.0', '1.9.3'), greaterThan(0), reason: 'compara números, no texto');
      expect(compararVersiones('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('ignora la "v", el build y las partes que faltan', () {
      expect(compararVersiones('v1.1.0', '1.1.0+2'), 0);
      expect(compararVersiones('1.1', '1.1.0'), 0);
    });
  });

  group('versionDesdeJson', () {
    test('toma el APK adjunto, sus notas y su huella SHA-256', () {
      final v = versionDesdeJson(_release())!;
      expect(v.version, '1.1.0');
      expect(v.urlApk, endsWith('costusoft-1.1.0.apk'));
      expect(v.tamanoBytes, 52428800);
      expect(v.sha256, 'abc123');
      expect(v.notas, contains('inactividad'));
    });

    test('sin APK adjunto no hay actualización', () {
      expect(versionDesdeJson(_release(conApk: false)), isNull);
    });
  });

  group('ControladorActualizacion.revisar', () {
    ProviderContainer contenedor(_FuenteFalsa fuente, {String instalada = '1.0.0'}) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          proveedorFuenteActualizaciones.overrideWithValue(fuente),
          proveedorVersionInstalada.overrideWith((ref) async => instalada),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('ofrece la versión nueva', () async {
      final c = contenedor(_FuenteFalsa(versionDesdeJson(_release())));
      await c.read(proveedorActualizacion.notifier).revisar();
      final estado = c.read(proveedorActualizacion);
      expect(estado, isA<ActualizacionDisponible>());
      expect((estado as ActualizacionDisponible).nueva.version, '1.1.0');
    });

    test('no ofrece nada si ya tiene la última', () async {
      final c = contenedor(_FuenteFalsa(versionDesdeJson(_release())), instalada: '1.1.0');
      await c.read(proveedorActualizacion.notifier).revisar();
      expect(c.read(proveedorActualizacion), isA<SinActualizacion>());
    });

    test('"Más tarde" no vuelve a ofrecer la misma versión', () async {
      final fuente = _FuenteFalsa(versionDesdeJson(_release()));
      final c = contenedor(fuente);
      final controlador = c.read(proveedorActualizacion.notifier);
      await controlador.revisar();
      controlador.masTarde();
      await controlador.revisar(forzar: true);
      expect(c.read(proveedorActualizacion), isA<SinActualizacion>());
      expect(fuente.consultas, 2);
    });

    test('no consulta GitHub más de una vez cada 6 horas', () async {
      final fuente = _FuenteFalsa(null);
      final c = contenedor(fuente);
      final controlador = c.read(proveedorActualizacion.notifier);
      await controlador.revisar();
      await controlador.revisar();
      expect(fuente.consultas, 1);
    });
  });
}
