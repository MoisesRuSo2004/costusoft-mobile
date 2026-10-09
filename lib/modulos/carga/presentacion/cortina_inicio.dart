import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/encabezado_domo.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/verificador_servidor.dart';
import '../../../nucleo/sin_conexion/estado_red.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/dominio/estado_sesion.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import 'logo_animado.dart';

/// Verifica el servidor y restaura la sesión. Sin conexión, la sesión se
/// restaura igual desde la copia local (si el usuario ya había entrado antes
/// en este dispositivo); si no hay copia, se muestra el error.
final _proveedorConexion = FutureProvider.autoDispose<Resultado<void>>((ref) async {
  final servidor = await ref.read(proveedorVerificadorServidor).verificar();
  switch (servidor) {
    case Falla(fallo: FalloRed() || FalloTiempoAgotado()):
      ref.read(proveedorRed.notifier).marcarSinConexion();
    case Falla(:final fallo):
      return Falla(fallo);
    case Exito():
      break;
  }
  return ref.read(proveedorSesion.notifier).restaurar();
});

/// Cortina de inicio: cubre la app con el azul de la marca mientras se arma
/// el logo y, en paralelo, se verifica el servidor y se restaura la sesión.
///
/// Cuando ambas cosas terminan, la cortina sube encogiéndose hasta volverse
/// el domo del ingreso (sin sesión) o desaparece hacia arriba (con sesión).
/// Debajo, el enrutador ya muestra la página de destino.
class CortinaInicio extends ConsumerStatefulWidget {
  const CortinaInicio({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CortinaInicio> createState() => _EstadoCortinaInicio();
}

class _EstadoCortinaInicio extends ConsumerState<CortinaInicio> with TickerProviderStateMixin {
  /// Armado del logo. La intro se ve completa aunque el servidor responda
  /// antes; si tarda más, la cortina espera con el logo quieto.
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
    ..addStatusListener((estado) {
      if (estado == AnimationStatus.completed) _intentarSalir();
    });

  /// Subida de la cortina.
  late final AnimationController _salida =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..addStatusListener((estado) {
        if (estado != AnimationStatus.completed) return;
        // Al cerrar la suscripción se liberan las imágenes del logo.
        _suscripcionCapas.close();
        setState(() => _terminada = true);
      });

  late final Animation<double> _subida = CurvedAnimation(parent: _salida, curve: const Cubic(0.7, 0, 0.2, 1));

  bool _terminada = false;

  late final ProviderSubscription<AsyncValue<CapasLogo>> _suscripcionCapas;

  /// `true` si la sesión quedó activa: la cortina sale por arriba en lugar
  /// de convertirse en el domo del ingreso.
  bool _haciaInicio = false;

  Timer? _temporizadorLento;
  bool _estaTardando = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(proveedorSesion, (_, _) => _intentarSalir());
    _suscripcionCapas = ref.listenManual(proveedorCapasLogo, (_, capas) {
      if (capas.hasValue || capas.hasError) _intro.forward();
    }, fireImmediately: true);
    _iniciarTemporizadorLento();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Reducir movimiento" del sistema: la cortina se abre casi sin animar.
    final sinAnimaciones = MediaQuery.disableAnimationsOf(context);
    _intro.duration = Duration(milliseconds: sinAnimaciones ? 300 : 2000);
    _salida.duration = Duration(milliseconds: sinAnimaciones ? 250 : 1100);
    // El logo del encabezado queda decodificado antes de descubrirlo.
    precacheImage(const AssetImage('assets/imagenes/logo_costusoft.png'), context);
  }

  /// Si el servidor tarda más de 6 s, se avisa que está "despertando".
  void _iniciarTemporizadorLento() {
    _temporizadorLento?.cancel();
    _estaTardando = false;
    _temporizadorLento = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _estaTardando = true);
    });
  }

  void _intentarSalir() {
    if (!mounted || !_intro.isCompleted || _salida.isAnimating || _salida.isCompleted) return;
    final sesion = ref.read(proveedorSesion);
    if (sesion is SesionPendiente) return;
    _temporizadorLento?.cancel();
    setState(() => _haciaInicio = sesion is SesionActiva);
    _salida.forward();
  }

  void _reintentar() {
    setState(_iniciarTemporizadorLento);
    ref.invalidate(_proveedorConexion);
  }

  @override
  void dispose() {
    _temporizadorLento?.cancel();
    _intro.dispose();
    _salida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_terminada) return widget.child;

    final conexion = ref.watch(_proveedorConexion);

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                label: 'CostuSoft Control',
                child: LayoutBuilder(
                  builder: (context, limites) => AnimatedBuilder(
                    animation: Listenable.merge([_intro, _subida]),
                    builder: (context, _) => _construirCortina(limites.biggest, conexion),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirCortina(Size pantalla, AsyncValue<Resultado<void>> conexion) {
    // Las capas se leen en cada cuadro: la intro arranca justo cuando cargan.
    final capas = _suscripcionCapas.read().value;
    final s = _subida.value;
    final ancho = pantalla.width;

    // El domo es un círculo con centro en el borde superior: tan grande que
    // tapa toda la pantalla al principio y del tamaño del encabezado al final.
    final radioInicial = math.sqrt(math.pow(ancho / 2, 2) + math.pow(pantalla.height, 2)) + 60;
    final radioFinal = _haciaInicio ? 0.0 : EncabezadoDomo.diametroDomo / 2;
    final radio = radioInicial + (radioFinal - radioInicial) * s;

    // El logo viaja del centro de la pantalla al lugar del logo del encabezado.
    final anchoLogoInicial = math.min(ancho * 0.64, 300.0);
    final anchoLogoFinal = _haciaInicio ? 120.0 : EncabezadoDomo.anchoLogo;
    final anchoLogo = anchoLogoInicial + (anchoLogoFinal - anchoLogoInicial) * s;
    final altoLogo = anchoLogo / EncabezadoDomo.proporcionLogo;
    final centroInicial = pantalla.height * 0.44;
    final centroFinal = _haciaInicio ? -altoLogo : EncabezadoDomo.centroLogo(EncabezadoDomo.altoPredeterminado);
    final centroLogo = centroInicial + (centroFinal - centroInicial) * s;

    // Al llegar al domo, la cortina se funde con el encabezado real.
    final opacidad = _haciaInicio ? 1.0 : 1 - const Interval(0.82, 1).transform(_salida.value);
    final opacidadEstado = 1 - (s * 5).clamp(0.0, 1.0);

    return IgnorePointer(
      ignoring: _salida.value > 0,
      child: Opacity(
        opacity: opacidad,
        child: Stack(
          children: [
            Positioned(
              left: ancho / 2 - radio,
              top: -radio,
              width: radio * 2,
              height: radio * 2,
              child: DomoAzul(diametro: radio * 2, brillo: s),
            ),
            Positioned(
              left: (ancho - anchoLogo) / 2,
              top: centroLogo - altoLogo / 2,
              width: anchoLogo,
              height: altoLogo,
              child: capas != null
                  ? CustomPaint(
                      painter: PintorLogoAnimado(capas: capas, avance: _intro),
                    )
                  : const SizedBox.shrink(),
            ),
            if (opacidadEstado > 0)
              Positioned(
                left: 32,
                right: 32,
                top: centroInicial + anchoLogoInicial / EncabezadoDomo.proporcionLogo / 2 + 44,
                child: Opacity(
                  opacity: opacidadEstado,
                  child: Center(child: _construirEstado(conexion)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Bajo el logo: nada mientras se arma; luego "conectando" o el error.
  Widget _construirEstado(AsyncValue<Resultado<void>> conexion) {
    final mensajeError = switch (conexion) {
      AsyncData(value: Falla(:final fallo)) => fallo.mensaje,
      AsyncError() => 'No fue posible verificar el servidor.',
      _ => null,
    };
    final Widget estado;
    if (mensajeError != null) {
      estado = _ErrorDeConexion(key: const ValueKey('error'), mensaje: mensajeError, alReintentar: _reintentar);
    } else if (_intro.isCompleted) {
      estado = _Conectando(
        key: const ValueKey('conectando'),
        mensaje: _estaTardando ? 'Despertando el servidor, puede tardar unos segundos…' : 'Conectando con CostuSoft…',
      );
    } else {
      estado = const SizedBox.shrink();
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: estado);
  }
}

class _Conectando extends StatelessWidget {
  const _Conectando({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 3,
              color: ColoresApp.verdeClaro,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            mensaje,
            key: ValueKey(mensaje),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
      ],
    );
  }
}

class _ErrorDeConexion extends StatelessWidget {
  const _ErrorDeConexion({super.key, required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, size: 32, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(height: 10),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: alReintentar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
      ],
    );
  }
}
