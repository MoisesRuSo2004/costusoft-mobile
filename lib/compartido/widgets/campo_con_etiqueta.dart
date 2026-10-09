import 'package:flutter/material.dart';

import '../../nucleo/tema/colores_app.dart';

/// Etiqueta encima del campo (con asterisco rojo si es obligatorio),
/// como en los formularios de la plataforma web.
class CampoConEtiqueta extends StatelessWidget {
  const CampoConEtiqueta({super.key, required this.etiqueta, required this.campo, this.obligatorio = false});

  final String etiqueta;
  final Widget campo;
  final bool obligatorio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: etiqueta,
            children: [
              if (obligatorio)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: ColoresApp.errorObligatorio),
                ),
            ],
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ColoresApp.textoEtiqueta),
        ),
        const SizedBox(height: 8),
        campo,
      ],
    );
  }
}
