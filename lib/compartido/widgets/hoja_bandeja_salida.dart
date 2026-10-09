import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/sin_conexion/bandeja_salida.dart';
import '../../nucleo/sin_conexion/estado_red.dart';
import '../../nucleo/sin_conexion/sincronizacion.dart';
import '../../nucleo/tema/colores_app.dart';
import '../../nucleo/utilidades/formatos.dart';
import 'aviso_en_linea.dart';
import 'estados_pantalla.dart';

/// Bandeja de salida: los cambios hechos sin conexión, su estado y qué hacer
/// con los que el servidor rechazó.
Future<void> mostrarBandejaSalida(BuildContext context) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _HojaBandejaSalida());

class _HojaBandejaSalida extends ConsumerWidget {
  const _HojaBandejaSalida();

  Future<void> _descartar(BuildContext context, WidgetRef ref, AccionPendiente accion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Descartar cambio'),
        content: Text(
          accion.estado == EstadoAccion.conflicto
              ? '«${accion.solicitud.descripcion}» se quitará de la bandeja.'
              : '«${accion.solicitud.descripcion}» todavía no se ha enviado. Si lo descartas, no se aplicará.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Volver')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColoresApp.error),
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmado ?? false) await ref.read(proveedorSincronizacion.notifier).descartar(accion.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(proveedorSincronizacion);
    final enLinea = ref.watch(proveedorRed.select((r) => r.enLinea));
    final acciones = estado.acciones;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Bandeja de salida', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                enLinea
                    ? 'Los cambios se envían en el orden en que los hiciste.'
                    : 'Sin conexión. Se enviarán solos, en orden, al recuperar la red.',
                style: const TextStyle(fontSize: 13, color: ColoresApp.textoSecundario),
              ),
              const SizedBox(height: 14),
              if (acciones.isEmpty)
                const AvisoEnLinea.exito('No hay cambios pendientes: todo está enviado.')
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: acciones.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _FilaAccion(accion: acciones[i], alDescartar: () => _descartar(context, ref, acciones[i])),
                  ),
                ),
              if (estado.conflictos > 0) ...[
                const SizedBox(height: 12),
                const AvisoEnLinea.informacion(
                  'Los cambios rechazados no se aplicaron: normalmente otra persona ya había procesado ese '
                  'registro. Revísalo en la pantalla correspondiente y descarta el aviso.',
                ),
              ],
              if (estado.pendientes > 0) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: estado.enviando
                      ? null
                      : () => enLinea
                            ? unawaited(ref.read(proveedorSincronizacion.notifier).sincronizar())
                            : unawaited(ref.read(proveedorRed.notifier).comprobar()),
                  icon: estado.enviando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                      : Icon(enLinea ? Icons.send_rounded : Icons.wifi_find_rounded),
                  label: Text(enLinea ? 'Enviar ahora' : 'Comprobar conexión'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaAccion extends StatelessWidget {
  const _FilaAccion({required this.accion, required this.alDescartar});

  final AccionPendiente accion;
  final VoidCallback alDescartar;

  @override
  Widget build(BuildContext context) {
    final conflicto = accion.estado == EstadoAccion.conflicto;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            conflicto ? Icons.error_outline_rounded : Icons.schedule_send_rounded,
            color: conflicto ? ColoresApp.sinStockTexto : ColoresApp.azulMedio,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        accion.solicitud.descripcion,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    if (conflicto)
                      const Insignia(
                        texto: 'Rechazado',
                        fondo: ColoresApp.sinStockFondo,
                        color: ColoresApp.sinStockTexto,
                      )
                    else
                      const InsigniaPorEnviar(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    'Hecho ${Formatos.haceCuanto(accion.creadaEn)}',
                    if (!conflicto && accion.intentos > 0)
                      accion.intentos == 1 ? '1 intento' : '${accion.intentos} intentos',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                ),
                if (conflicto && accion.ultimoError != null) ...[
                  const SizedBox(height: 4),
                  Text(accion.ultimoError!, style: const TextStyle(fontSize: 12.5, color: ColoresApp.sinStockTexto)),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Descartar',
            onPressed: alDescartar,
            icon: const Icon(Icons.close_rounded, size: 20, color: ColoresApp.textoTenue),
          ),
        ],
      ),
    );
  }
}
