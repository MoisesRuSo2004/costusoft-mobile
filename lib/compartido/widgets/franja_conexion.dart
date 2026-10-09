import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/sin_conexion/estado_red.dart';
import '../../nucleo/sin_conexion/sincronizacion.dart';
import '../../nucleo/tema/colores_app.dart';
import '../../nucleo/utilidades/formatos.dart';
import 'hoja_bandeja_salida.dart';

/// Franja sobre la barra inferior: sin conexión, cambios por enviar o
/// cambios que el servidor rechazó. No ocupa espacio si todo está al día.
class FranjaConexion extends ConsumerWidget {
  const FranjaConexion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final red = ref.watch(proveedorRed);
    final sincronizacion = ref.watch(proveedorSincronizacion);
    final pendientes = sincronizacion.pendientes;
    final conflictos = sincronizacion.conflictos;
    String porEnviar(int n) => n == 1 ? '1 cambio por enviar' : '$n cambios por enviar';

    final (IconData, String, Color, Color)? contenido;
    if (!red.enLinea) {
      contenido = (
        Icons.cloud_off_rounded,
        [
          'Sin conexión',
          if (red.copiaDe != null) 'datos de ${Formatos.haceCuanto(red.copiaDe!)}',
          if (pendientes > 0) porEnviar(pendientes),
        ].join(' · '),
        ColoresApp.stockBajoFondo,
        ColoresApp.stockBajoTexto,
      );
    } else if (conflictos > 0) {
      contenido = (
        Icons.error_outline_rounded,
        conflictos == 1
            ? '1 cambio no se pudo aplicar · Revisar'
            : '$conflictos cambios no se pudieron aplicar · Revisar',
        ColoresApp.sinStockFondo,
        ColoresApp.sinStockTexto,
      );
    } else if (pendientes > 0) {
      contenido = (
        Icons.sync_rounded,
        sincronizacion.enviando
            ? 'Enviando ${porEnviar(pendientes).replaceFirst(' por enviar', '')}…'
            : porEnviar(pendientes),
        ColoresApp.infoFondo,
        ColoresApp.azulMedio,
      );
    } else {
      contenido = null;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: contenido == null
          ? const SizedBox(width: double.infinity)
          : Material(
              color: contenido.$3,
              child: InkWell(
                onTap: () => (pendientes + conflictos > 0)
                    ? mostrarBandejaSalida(context)
                    : unawaited(ref.read(proveedorRed.notifier).comprobar()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(
                    children: [
                      Icon(contenido.$1, size: 18, color: contenido.$4),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contenido.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: contenido.$4, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: contenido.$4),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
