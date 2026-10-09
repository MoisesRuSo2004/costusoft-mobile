import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../nucleo/tema/colores_app.dart';

/// Encabezado azul en forma de domo con el logo de CostuSoft Control.
/// Réplica del encabezado móvil del login web (`(auth)/layout.tsx`):
/// círculo de 420 px con la mitad superior oculta, cuadrícula, brillo verde,
/// partículas flotantes y un "respiro" suave del domo.
class EncabezadoDomo extends StatefulWidget {
  const EncabezadoDomo({super.key, this.alto = altoPredeterminado});

  final double alto;

  // Medidas públicas para que la cortina de inicio termine justo sobre el domo.
  static const altoPredeterminado = 210.0;
  static const diametroDomo = 420.0;
  static const anchoLogo = 170.0;
  static const margenInferiorLogo = 40.0;

  /// Ancho / alto de `logo_costusoft.png` (720 × 563 px).
  static const proporcionLogo = 720 / 563;

  /// Centro vertical del logo dentro de un encabezado de alto [alto].
  static double centroLogo(double alto) => alto - margenInferiorLogo - anchoLogo / proporcionLogo / 2;

  @override
  State<EncabezadoDomo> createState() => _EstadoEncabezadoDomo();
}

class _EstadoEncabezadoDomo extends State<EncabezadoDomo> with TickerProviderStateMixin {
  static const _diametro = EncabezadoDomo.diametroDomo;

  /// Marca cada cuadro de la animación continua; el tiempo real lo da [_reloj].
  late final AnimationController _ciclo = AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..repeat();
  final _reloj = Stopwatch()..start();

  /// Entrada del logo (0,75 s con 0,25 s de espera, como en la web).
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final Animation<double> _entradaLogo = CurvedAnimation(
    parent: _entrada,
    curve: const Interval(0.25, 1, curve: Cubic(0.23, 1, 0.32, 1)),
  );

  @override
  void dispose() {
    _reloj.stop();
    _ciclo.dispose();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.alto,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, limites) {
          final ancho = limites.maxWidth;
          return ClipRect(
            child: AnimatedBuilder(
              animation: _ciclo,
              builder: (context, child) {
                final segundos = _reloj.elapsedMilliseconds / 1000;
                // El domo crece un 2,2 % y vuelve, cada 6 s.
                final escala = 1 + 0.022 * (0.5 - 0.5 * math.cos(2 * math.pi * segundos / 6));
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -_diametro / 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Transform.scale(
                          scale: escala,
                          child: const DomoAzul(diametro: _diametro),
                        ),
                      ),
                    ),
                    for (final particula in _particulas) particula.construir(segundos, ancho),
                    // Desvanecido inferior para fundir el domo con el fondo blanco.
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00FFFFFF), Color(0x80FFFFFF), Colors.white],
                            stops: [0, 0.5, 1],
                          ),
                        ),
                      ),
                    ),
                    child!,
                  ],
                );
              },
              child: Positioned(
                left: 0,
                right: 0,
                bottom: EncabezadoDomo.margenInferiorLogo,
                child: FadeTransition(
                  opacity: _entradaLogo,
                  child: AnimatedBuilder(
                    animation: _entradaLogo,
                    builder: (_, logo) => Transform.translate(
                      offset: Offset(0, 14 * (1 - _entradaLogo.value)),
                      child: Transform.scale(scale: 0.92 + 0.08 * _entradaLogo.value, child: logo),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/imagenes/logo_costusoft.png',
                        width: EncabezadoDomo.anchoLogo,
                        semanticLabel: 'CostuSoft Control',
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// El círculo azul con su cuadrícula, brillo verde y aro interior.
/// También lo usa la cortina de inicio, que lo encoge hasta este tamaño.
class DomoAzul extends StatelessWidget {
  const DomoAzul({super.key, required this.diametro, this.brillo = 1});

  final double diametro;

  /// Intensidad (0 a 1) del brillo verde y la cuadrícula. La cortina de
  /// inicio la sube mientras se encoge: a pantalla completa es azul liso.
  final double brillo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          // 150° en CSS ≈ de arriba-izquierda a abajo-derecha.
          begin: Alignment(-0.5, -0.87),
          end: Alignment(0.5, 0.87),
          colors: [ColoresApp.azulMedio, ColoresApp.azulMarino, ColoresApp.azulProfundo],
          stops: [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(color: ColoresApp.azulMarino.withValues(alpha: 0.45), blurRadius: 60, offset: const Offset(0, 20)),
          BoxShadow(color: ColoresApp.azulMarino.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.07 * brillo,
              child: const CustomPaint(painter: _PintorCuadricula()),
            ),
            // Brillo verde interior.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.1, 0.44),
                  radius: 0.52,
                  colors: [
                    const Color(0x4749C21B).withValues(alpha: 0.28 * brillo),
                    const Color(0x0049C21B),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuadrícula de 36 px como el patrón SVG de la web.
class _PintorCuadricula extends CustomPainter {
  const _PintorCuadricula();

  @override
  void paint(Canvas canvas, Size size) {
    final lapiz = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.8;
    for (var x = 0.0; x <= size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lapiz);
    }
    for (var y = 0.0; y <= size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lapiz);
    }
  }

  @override
  bool shouldRepaint(_PintorCuadricula anterior) => false;
}

/// Punto luminoso que sube y baja suavemente (mismos valores que la web).
class _Particula {
  const _Particula({
    required this.tamano,
    required this.color,
    required this.arriba,
    required this.fraccionX,
    required this.desdeIzquierda,
    required this.desplazamiento,
    required this.duracion,
    required this.retraso,
  });

  final double tamano;
  final Color color;
  final double arriba;
  final double fraccionX;
  final bool desdeIzquierda;
  final double desplazamiento;
  final double duracion;
  final double retraso;

  Widget construir(double segundos, double ancho) {
    final fase = 2 * math.pi * ((segundos - retraso) / duracion);
    final avance = 0.5 - 0.5 * math.cos(fase); // 0 → 1 → 0
    return Positioned(
      top: arriba + desplazamiento * avance,
      left: desdeIzquierda ? ancho * fraccionX : null,
      right: desdeIzquierda ? null : ancho * fraccionX,
      child: Opacity(
        opacity: 0.6 + 0.4 * avance,
        child: Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

const _particulas = [
  _Particula(
    tamano: 6,
    color: Color(0xB349C21B),
    arriba: 88,
    fraccionX: 0.32,
    desdeIzquierda: true,
    desplazamiento: -14,
    duracion: 3.2,
    retraso: 0.4,
  ),
  _Particula(
    tamano: 4,
    color: Color(0x59FFFFFF),
    arriba: 110,
    fraccionX: 0.28,
    desdeIzquierda: false,
    desplazamiento: -9,
    duracion: 4,
    retraso: 1.1,
  ),
  _Particula(
    tamano: 5,
    color: Color(0x7349C21B),
    arriba: 65,
    fraccionX: 0.40,
    desdeIzquierda: false,
    desplazamiento: -11,
    duracion: 3.6,
    retraso: 0,
  ),
  _Particula(
    tamano: 3,
    color: Color(0x40FFFFFF),
    arriba: 140,
    fraccionX: 0.44,
    desdeIzquierda: true,
    desplazamiento: -7,
    duracion: 4.5,
    retraso: 1.8,
  ),
];
