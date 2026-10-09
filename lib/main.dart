import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'aplicacion.dart';
import 'nucleo/notificaciones/controlador_avisos.dart';
import 'nucleo/notificaciones/servicio_notificaciones.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  // Avisos push (Firebase). Si no se puede iniciar, la app funciona sin ellos.
  final firebaseDisponible = await iniciarFirebase();
  // Riverpod 3 reintenta solo los proveedores que fallan; aquí se desactiva:
  // los errores se muestran con un botón "Reintentar" y no se insiste en
  // segundo plano contra el backend.
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [proveedorFirebaseDisponible.overrideWithValue(firebaseDisponible)],
      child: const AplicacionCostuSoft(),
    ),
  );
}
