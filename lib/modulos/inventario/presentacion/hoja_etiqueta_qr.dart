import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../nucleo/tema/colores_app.dart';
import '../../bodega/dominio/codigo_qr.dart';
import '../dominio/insumo.dart';

/// Etiqueta QR de un insumo para pegar en el rollo, la caja o el estante.
/// Bodega la escanea para ver el insumo y verificar sus movimientos.
Future<void> mostrarEtiquetaQr(BuildContext context, Insumo insumo) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Etiqueta del insumo', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Imprímela o muéstrala en pantalla para escanearla desde Bodega.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Recuadro con borde, como quedaría impreso.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColoresApp.bordeFuerte, width: 1.5),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: codigoQrDeInsumo(insumo.id),
                  size: 210,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ColoresApp.azulNoche),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: ColoresApp.azulNoche,
                  ),
                  semanticsLabel: 'Código QR del insumo ${insumo.nombre}',
                ),
                const SizedBox(height: 10),
                Text(
                  insumo.nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${insumo.tipo} · Código ${insumo.id}',
                  style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            codigoQrDeInsumo(insumo.id),
            style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue, fontFamily: 'monospace'),
          ),
        ],
      ),
    ),
  ),
);
