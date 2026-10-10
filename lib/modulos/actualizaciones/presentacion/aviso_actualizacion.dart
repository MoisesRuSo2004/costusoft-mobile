import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores_app.dart';
import 'controlador_actualizacion.dart';

/// Revisa si hay versión nueva al abrir la app y al volver a ella, y muestra
/// una tarjeta abajo para actualizar sin salir de la app.
class AvisoActualizacion extends ConsumerStatefulWidget {
  const AvisoActualizacion({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AvisoActualizacion> createState() => _AvisoActualizacionState();
}

class _AvisoActualizacionState extends ConsumerState<AvisoActualizacion> with WidgetsBindingObserver {
  ControladorActualizacion get _controlador => ref.read(proveedorActualizacion.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Después de la cortina de inicio, sin competir con la carga de la app.
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) unawaited(_controlador.revisar());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) unawaited(_controlador.revisar());
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(proveedorActualizacion);
    return Stack(
      children: [
        widget.child,
        if (estado is! SinActualizacion)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: _TarjetaActualizacion(estado: estado, controlador: _controlador),
            ),
          ),
      ],
    );
  }
}

class _TarjetaActualizacion extends StatelessWidget {
  const _TarjetaActualizacion({required this.estado, required this.controlador});

  final EstadoActualizacion estado;
  final ControladorActualizacion controlador;

  @override
  Widget build(BuildContext context) {
    final (version, notas) = switch (estado) {
      ActualizacionDisponible(:final nueva) ||
      DescargandoActualizacion(:final nueva) ||
      InstalandoActualizacion(:final nueva) ||
      ErrorActualizacion(:final nueva) => (nueva.version, nueva.notas),
      SinActualizacion() => ('', ''),
    };
    final tamano = switch (estado) {
      ActualizacionDisponible(:final nueva) when nueva.tamanoBytes > 0 =>
        ' · ${(nueva.tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
      _ => '',
    };

    return Material(
      elevation: 12,
      shadowColor: Colors.black38,
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColoresApp.azulNoche.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: ColoresApp.azulNoche),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nueva versión de CostuSoft',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5, color: ColoresApp.textoTitulo),
                      ),
                      Text(
                        'Versión $version$tamano',
                        style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (notas.isNotEmpty && estado is ActualizacionDisponible) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(
                    notas,
                    style: const TextStyle(fontSize: 13, color: ColoresApp.textoEtiqueta, height: 1.4),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...switch (estado) {
              DescargandoActualizacion(:final porcentaje) => [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(value: porcentaje / 100, minHeight: 6),
                ),
                const SizedBox(height: 6),
                Text(
                  'Descargando… $porcentaje %',
                  style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: 4),
              ],
              InstalandoActualizacion() => [
                const Text(
                  'Confirma la instalación en la ventana de Android. La app se reiniciará con la nueva versión.',
                  style: TextStyle(fontSize: 13, color: ColoresApp.textoSecundario, height: 1.4),
                ),
                const SizedBox(height: 4),
              ],
              ErrorActualizacion(:final mensaje) => [
                Text(mensaje, style: const TextStyle(fontSize: 13, color: ColoresApp.error, height: 1.4)),
                const SizedBox(height: 4),
                _Botones(controlador: controlador, textoPrincipal: 'Reintentar'),
              ],
              _ => [_Botones(controlador: controlador, textoPrincipal: 'Actualizar ahora')],
            },
          ],
        ),
      ),
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones({required this.controlador, required this.textoPrincipal});

  final ControladorActualizacion controlador;
  final String textoPrincipal;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(onPressed: controlador.masTarde, child: const Text('Más tarde')),
      const SizedBox(width: 8),
      FilledButton.icon(
        onPressed: controlador.actualizar,
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text(textoPrincipal),
      ),
    ],
  );
}
