import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../nucleo/utilidades/registro_app.dart';
import '../datos/fuente_actualizaciones.dart';
import '../dominio/version_publicada.dart';

/// Estado de la actualización de la app.
sealed class EstadoActualizacion {
  const EstadoActualizacion();
}

/// Al día, sin revisar todavía, o el usuario eligió "Más tarde".
final class SinActualizacion extends EstadoActualizacion {
  const SinActualizacion();
}

final class ActualizacionDisponible extends EstadoActualizacion {
  const ActualizacionDisponible({required this.instalada, required this.nueva});

  final String instalada;
  final VersionPublicada nueva;
}

final class DescargandoActualizacion extends EstadoActualizacion {
  const DescargandoActualizacion(this.nueva, this.porcentaje);

  final VersionPublicada nueva;
  final int porcentaje;
}

/// Descargada: Android muestra su ventana para confirmar la instalación.
final class InstalandoActualizacion extends EstadoActualizacion {
  const InstalandoActualizacion(this.nueva);

  final VersionPublicada nueva;
}

final class ErrorActualizacion extends EstadoActualizacion {
  const ErrorActualizacion(this.nueva, this.mensaje);

  final VersionPublicada nueva;
  final String mensaje;
}

final proveedorFuenteActualizaciones = Provider<FuenteActualizaciones>((ref) => FuenteActualizaciones());

/// Versión instalada ("1.1.0"), inyectable en pruebas.
final proveedorVersionInstalada = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

final proveedorActualizacion = NotifierProvider<ControladorActualizacion, EstadoActualizacion>(
  ControladorActualizacion.new,
);

/// Busca versiones nuevas en GitHub Releases al abrir la app y al volver a
/// ella (como mucho cada 6 h), y las instala desde la app.
///
/// Android no permite instalar sin preguntar: tras la descarga muestra su
/// ventana "¿Quieres actualizar esta app?". El APK debe estar firmado con la
/// misma llave que la versión instalada.
class ControladorActualizacion extends Notifier<EstadoActualizacion> {
  static const _cadaCuanto = Duration(hours: 6);

  DateTime? _ultimaRevision;
  String? _omitida; // versión para la que eligió "Más tarde"
  StreamSubscription<OtaEvent>? _descarga;

  @override
  EstadoActualizacion build() {
    ref.onDispose(() => _descarga?.cancel());
    return const SinActualizacion();
  }

  /// Solo en la app de Android (en web siempre se carga la última versión).
  static bool get disponibleEnPlataforma => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> revisar({bool forzar = false}) async {
    if (!disponibleEnPlataforma || state is DescargandoActualizacion || state is InstalandoActualizacion) return;
    final ahora = DateTime.now();
    if (!forzar && _ultimaRevision != null && ahora.difference(_ultimaRevision!) < _cadaCuanto) return;
    _ultimaRevision = ahora;
    try {
      final instalada = await ref.read(proveedorVersionInstalada.future);
      final nueva = await ref.read(proveedorFuenteActualizaciones).ultima();
      if (nueva == null || compararVersiones(nueva.version, instalada) <= 0 || nueva.version == _omitida) return;
      state = ActualizacionDisponible(instalada: instalada, nueva: nueva);
    } on Object catch (e) {
      // Sin red o GitHub no responde: se intentará la próxima vez.
      registroApp.w('No se pudo revisar si hay actualizaciones: $e');
    }
  }

  void masTarde() {
    if (state case ActualizacionDisponible(:final nueva) || ErrorActualizacion(:final nueva)) _omitida = nueva.version;
    state = const SinActualizacion();
  }

  void actualizar() {
    final nueva = switch (state) {
      ActualizacionDisponible(:final nueva) || ErrorActualizacion(:final nueva) => nueva,
      _ => null,
    };
    if (nueva == null) return;
    state = DescargandoActualizacion(nueva, 0);
    try {
      _descarga = OtaUpdate()
          .execute(nueva.urlApk, destinationFilename: 'costusoft-${nueva.version}.apk', sha256checksum: nueva.sha256)
          .listen(
            (evento) => _alEvento(nueva, evento),
            onError: (Object e) => state = ErrorActualizacion(nueva, 'No se pudo descargar la actualización.'),
          );
    } on Object catch (e) {
      registroApp.w('No se pudo iniciar la actualización: $e');
      state = ErrorActualizacion(nueva, 'No se pudo iniciar la actualización.');
    }
  }

  void _alEvento(VersionPublicada nueva, OtaEvent evento) {
    state = switch (evento.status) {
      OtaStatus.DOWNLOADING => DescargandoActualizacion(nueva, int.tryParse(evento.value ?? '') ?? 0),
      OtaStatus.INSTALLING || OtaStatus.INSTALLATION_DONE => InstalandoActualizacion(nueva),
      OtaStatus.PERMISSION_NOT_GRANTED_ERROR => ErrorActualizacion(
        nueva,
        'Permite a CostuSoft instalar aplicaciones (Ajustes › Instalar apps desconocidas) y vuelve a intentarlo.',
      ),
      OtaStatus.CHECKSUM_ERROR => ErrorActualizacion(nueva, 'El archivo descargado no es válido. Vuelve a intentarlo.'),
      OtaStatus.CANCELED => ActualizacionDisponible(instalada: '', nueva: nueva),
      OtaStatus.DOWNLOAD_ERROR => ErrorActualizacion(nueva, 'Se interrumpió la descarga. Revisa tu conexión.'),
      OtaStatus.ALREADY_RUNNING_ERROR => state,
      OtaStatus.INSTALLATION_ERROR || OtaStatus.INTERNAL_ERROR => ErrorActualizacion(
        nueva,
        'No se pudo instalar la actualización. Vuelve a intentarlo.',
      ),
    };
  }
}
