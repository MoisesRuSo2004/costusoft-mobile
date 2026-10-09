import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bandeja_salida.dart';
import 'base_datos_local.dart';
import 'copia_local.dart';

/// Base SQLite del dispositivo (una sola instancia para toda la app).
final proveedorBaseDatosLocal = Provider<BaseDatosLocal>((ref) {
  final bd = BaseDatosLocal();
  ref.onDispose(bd.close);
  return bd;
});

final proveedorCopiaLocal = Provider<CopiaLocal>((ref) => CopiaLocalDrift(ref.watch(proveedorBaseDatosLocal)));

final proveedorBandejaSalida = Provider<BandejaSalida>((ref) => BandejaSalidaDrift(ref.watch(proveedorBaseDatosLocal)));
