import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';

/// Ruta inicial mientras se restaura la sesión (ver `guardia_rutas.dart`).
/// No se llega a ver: la tapa la `CortinaInicio`, que es la que verifica el
/// servidor, restaura la sesión y muestra el avance o los errores.
class PaginaCarga extends StatelessWidget {
  const PaginaCarga({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(color: ColoresApp.azulMarino);
}
