import 'package:flutter/material.dart';

import '../../nucleo/tema/colores_app.dart';

/// El motor de predicción estaba dormido y se está despertando.
class AvisoDespertandoMotor extends StatelessWidget {
  const AvisoDespertandoMotor({super.key, required this.segundos});

  final int segundos;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Despertando el motor de análisis… $segundos s',
              style: const TextStyle(fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
            ),
            const SizedBox(height: 4),
            const Text(
              'Si nadie lo usó en los últimos minutos, el servidor lo apaga para ahorrar recursos. '
              'Vuelve en 30 a 60 segundos; no hace falta salir de la pantalla.',
              style: TextStyle(fontSize: 13, color: ColoresApp.textoSecundario, height: 1.4),
            ),
          ],
        ),
      ),
    ],
  );
}
