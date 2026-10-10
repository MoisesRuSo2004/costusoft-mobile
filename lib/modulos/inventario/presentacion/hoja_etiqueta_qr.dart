import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../nucleo/tema/colores_app.dart';
import '../../bodega/dominio/codigo_qr.dart';
import '../dominio/insumo.dart';

/// Etiqueta QR de un insumo para pegar en el rollo, la caja o el estante.
/// Bodega la escanea para ver el insumo y verificar sus movimientos.
///
/// Desde aquí se comparte como imagen; para imprimir varias en una hoja está
/// la web (Inventario › Etiquetas QR), que genera el mismo código.
Future<void> mostrarEtiquetaQr(BuildContext context, Insumo insumo) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _HojaEtiquetaQr(insumo: insumo),
);

/// Nombre de archivo legible y sin tildes: `etiqueta-8-aguja.png`.
String nombreArchivoEtiqueta(Insumo insumo) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
  final base = insumo.nombre
      .toLowerCase()
      .split('')
      .map((c) => tildes[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'etiqueta-${insumo.id}${base.isEmpty ? '' : '-$base'}.png';
}

class _HojaEtiquetaQr extends StatefulWidget {
  const _HojaEtiquetaQr({required this.insumo});

  final Insumo insumo;

  @override
  State<_HojaEtiquetaQr> createState() => _HojaEtiquetaQrState();
}

class _HojaEtiquetaQrState extends State<_HojaEtiquetaQr> {
  final _claveEtiqueta = GlobalKey();
  final _claveBoton = GlobalKey();
  bool _compartiendo = false;

  /// Captura la etiqueta tal como se ve (a 3× para que imprima nítida) y la
  /// comparte como PNG con el menú del sistema.
  Future<void> _compartir() async {
    setState(() => _compartiendo = true);
    try {
      final limite = _claveEtiqueta.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await limite.toImage(pixelRatio: 3);
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      imagen.dispose();
      if (datos == null) throw StateError('No se pudo generar la imagen');

      // El iPad necesita saber desde dónde abrir el menú de compartir.
      final boton = _claveBoton.currentContext?.findRenderObject() as RenderBox?;
      final origen = boton == null ? null : boton.localToGlobal(Offset.zero) & boton.size;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(datos.buffer.asUint8List(), mimeType: 'image/png')],
          fileNameOverrides: [nombreArchivoEtiqueta(widget.insumo)],
          text: 'Etiqueta QR · ${widget.insumo.nombre}',
          sharePositionOrigin: origen,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo compartir la etiqueta. Intenta de nuevo.')));
      }
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insumo = widget.insumo;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Etiqueta del insumo', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Compártela para imprimirla o muéstrala en pantalla para escanearla desde Bodega.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Recuadro con borde, como quedaría impreso. Es lo que se comparte.
            RepaintBoundary(
              key: _claveEtiqueta,
              child: Container(
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
            ),
            const SizedBox(height: 12),
            Text(
              codigoQrDeInsumo(insumo.id),
              style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: _claveBoton,
                onPressed: _compartiendo ? null : _compartir,
                icon: _compartiendo
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.share_rounded),
                label: Text(_compartiendo ? 'Preparando imagen…' : 'Compartir imagen'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para imprimir varias en una hoja, usa la web: Inventario › Etiquetas QR.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColoresApp.textoTenue, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
