import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores_app.dart';
import '../dominio/estado_sesion.dart';
import 'controlador_sesion.dart';

/// Cierra la sesión tras un tiempo sin usar la app, como la web
/// (`useSessionTimeout`: 30 min, con aviso 5 min antes).
///
/// - Cualquier toque cuenta como actividad.
/// - Si la app vuelve del segundo plano después del límite, se cierra al
///   instante (los temporizadores no corren con la app suspendida).
/// - Al cerrarse, el login muestra el motivo. Los datos sin enviar se
///   conservan para cuando el mismo usuario vuelva a entrar.
class GuardiaInactividad extends ConsumerStatefulWidget {
  const GuardiaInactividad({
    super.key,
    required this.child,
    this.limite = const Duration(minutes: 30),
    this.aviso = const Duration(minutes: 5),
    this.revision = const Duration(seconds: 5),
    this.ahora = DateTime.now,
  });

  final Widget child;

  /// Tiempo sin actividad tras el cual se cierra la sesión.
  final Duration limite;

  /// Cuánto antes del cierre se muestra el aviso con la cuenta regresiva.
  final Duration aviso;

  /// Cada cuánto se revisa el tiempo transcurrido.
  final Duration revision;

  /// Reloj (inyectable en las pruebas).
  final DateTime Function() ahora;

  @override
  ConsumerState<GuardiaInactividad> createState() => _GuardiaInactividadState();
}

class _GuardiaInactividadState extends ConsumerState<GuardiaInactividad> with WidgetsBindingObserver {
  late DateTime _ultimaActividad;
  Timer? _reloj;

  /// Tiempo que falta para el cierre mientras se muestra el aviso.
  Duration? _restante;

  bool get _conSesion => ref.read(proveedorSesion) is SesionActiva;

  @override
  void initState() {
    super.initState();
    _ultimaActividad = widget.ahora();
    WidgetsBinding.instance.addObserver(this);
    _reloj = Timer.periodic(widget.revision, (_) => _revisar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reloj?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _revisar();
  }

  void _registrarActividad() {
    _ultimaActividad = widget.ahora();
    if (_restante != null) setState(() => _restante = null);
  }

  void _revisar() {
    if (!mounted) return;
    if (!_conSesion) {
      _ultimaActividad = widget.ahora();
      if (_restante != null) setState(() => _restante = null);
      return;
    }
    final inactivo = widget.ahora().difference(_ultimaActividad);
    if (inactivo >= widget.limite) {
      setState(() => _restante = null);
      unawaited(ref.read(proveedorSesion.notifier).cerrarPorInactividad());
      return;
    }
    final falta = widget.limite - inactivo;
    if (falta <= widget.aviso) {
      setState(() => _restante = falta);
    } else if (_restante != null) {
      setState(() => _restante = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al iniciar sesión se empieza a contar desde cero.
    ref.listen(proveedorSesion, (anterior, actual) {
      if (actual is SesionActiva && anterior is! SesionActiva) _registrarActividad();
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registrarActividad(),
      child: Stack(
        children: [
          widget.child,
          if (_restante case final restante?)
            _AvisoInactividad(
              restante: restante,
              alSeguir: _registrarActividad,
              alCerrar: () => ref.read(proveedorSesion.notifier).cerrarSesion(),
            ),
        ],
      ),
    );
  }
}

/// Aviso "Tu sesión se cerrará en m:ss" sobre toda la app.
class _AvisoInactividad extends StatelessWidget {
  const _AvisoInactividad({required this.restante, required this.alSeguir, required this.alCerrar});

  final Duration restante;
  final VoidCallback alSeguir;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final minutos = restante.inMinutes;
    final segundos = (restante.inSeconds % 60).toString().padLeft(2, '0');
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 40, color: ColoresApp.azulNoche),
                      const SizedBox(height: 12),
                      const Text(
                        '¿Sigues ahí?',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: 'Por seguridad, tu sesión se cerrará en ',
                          children: [
                            TextSpan(
                              text: '$minutos:$segundos',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: ColoresApp.textoTitulo),
                            ),
                            const TextSpan(text: ' por inactividad.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14.5, color: ColoresApp.textoSecundario, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(onPressed: alSeguir, child: const Text('Seguir conectado')),
                      ),
                      TextButton(onPressed: alCerrar, child: const Text('Cerrar sesión')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
