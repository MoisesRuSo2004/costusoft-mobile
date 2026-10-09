import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Capas del logo de CostuSoft Control para la animación de inicio.
///
/// `logo_costusoft.png` se partió en cinco PNG del mismo tamaño (720 × 563)
/// que, apilados, reproducen el logo píxel a píxel: así, al terminar la
/// animación, el logo es idéntico al del encabezado del ingreso.
class CapasLogo {
  const CapasLogo({
    required this.barras,
    required this.hilo,
    required this.aguja,
    required this.texto,
    required this.lema,
  });

  final ui.Image barras;
  final ui.Image hilo;
  final ui.Image aguja;
  final ui.Image texto;
  final ui.Image lema;

  static Future<CapasLogo> cargar() async {
    final imagenes = await Future.wait([
      for (final capa in ['barras', 'hilo', 'aguja', 'texto', 'lema'])
        _cargarImagen('assets/imagenes/intro/logo_$capa.png'),
    ]);
    return CapasLogo(barras: imagenes[0], hilo: imagenes[1], aguja: imagenes[2], texto: imagenes[3], lema: imagenes[4]);
  }

  static Future<ui.Image> _cargarImagen(String ruta) async {
    final datos = await rootBundle.load(ruta);
    final codec = await ui.instantiateImageCodec(datos.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  void liberar() {
    for (final imagen in [barras, hilo, aguja, texto, lema]) {
      imagen.dispose();
    }
  }
}

/// Se descarta cuando la cortina sale de pantalla.
final proveedorCapasLogo = FutureProvider.autoDispose<CapasLogo>((ref) async {
  final capas = await CapasLogo.cargar();
  ref.onDispose(capas.liberar);
  return capas;
});

/// Dibuja el logo según el avance de la intro ([avance] de 0 a 1):
/// 1. entra la aguja en diagonal,
/// 2. crecen las tres barras como una gráfica,
/// 3. el hilo se "cose" desde el ojo de la aguja,
/// 4. aparecen el nombre y el lema.
class PintorLogoAnimado extends CustomPainter {
  PintorLogoAnimado({required this.capas, required this.avance}) : super(repaint: avance);

  final CapasLogo capas;
  final Animation<double> avance;

  static const _ancho = 720.0;

  // Tramos de la intro (fracciones de su duración total).
  static const _aguja = Interval(0, 0.30, curve: Curves.easeOutCubic);
  static const _barras = [
    Interval(0.12, 0.42, curve: Curves.easeOutCubic),
    Interval(0.20, 0.50, curve: Curves.easeOutCubic),
    Interval(0.28, 0.58, curve: Curves.easeOutCubic),
  ];
  static const _hilo = Interval(0.45, 0.80, curve: Curves.easeInOutCubic);
  static const _texto = Interval(0.62, 0.86, curve: Curves.easeOutCubic);
  static const _lema = Interval(0.76, 1, curve: Curves.easeOutCubic);

  /// Rectángulo de cada barra en el PNG (izquierda, arriba, derecha, abajo).
  static const _rectBarras = [
    Rect.fromLTRB(288, 164, 339, 258),
    Rect.fromLTRB(340, 126, 389, 258),
    Rect.fromLTRB(390, 91, 440, 258),
  ];

  /// Eje de la aguja: del extremo inferior izquierdo hacia el ojo.
  static const _ejeAguja = Offset(0.69, -0.72);

  /// Línea central del hilo en el PNG, desde el ojo de la aguja.
  static final Path _recorridoHilo = _suavizar(const [
    Offset(387, 44), Offset(400, 47), Offset(414, 50), Offset(425, 54), Offset(434, 58), //
    Offset(442, 63), Offset(450, 72), Offset(456, 82), Offset(459, 92), Offset(460, 105),
    Offset(458, 118), Offset(455, 130), Offset(451, 140), Offset(447, 150), Offset(441, 160),
    Offset(434, 170), Offset(427, 180), Offset(418, 190), Offset(408, 200), Offset(397, 210),
    Offset(390, 217.5), Offset(378, 225.5), Offset(366, 233.5), Offset(354, 239.5), Offset(342, 244.5),
    Offset(330, 249.5), Offset(318, 251.5), Offset(308, 252),
  ]);

  /// Curva suave que pasa por los puntos medios de la polilínea.
  static Path _suavizar(List<Offset> puntos) {
    final camino = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (var i = 1; i < puntos.length - 1; i++) {
      final medio = Offset.lerp(puntos[i], puntos[i + 1], 0.5)!;
      camino.quadraticBezierTo(puntos[i].dx, puntos[i].dy, medio.dx, medio.dy);
    }
    return camino..lineTo(puntos.last.dx, puntos.last.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = avance.value;
    canvas
      ..save()
      ..scale(size.width / _ancho);

    // 1. Aguja: se desliza a lo largo de su propio eje.
    final aguja = _aguja.transform(t);
    if (aguja > 0) _dibujar(canvas, capas.aguja, opacidad: aguja, desplazamiento: _ejeAguja * (-70 * (1 - aguja)));

    // 2. Barras: cada una se descubre de abajo hacia arriba.
    for (var i = 0; i < 3; i++) {
      final crecimiento = _barras[i].transform(t);
      if (crecimiento <= 0) continue;
      final rect = _rectBarras[i];
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(rect.left, rect.bottom - rect.height * crecimiento, rect.right, rect.bottom));
      _dibujar(canvas, capas.barras);
      canvas.restore();
    }

    // 3. Hilo: una máscara recorre su trazo; la punta deja un destello.
    final costura = _hilo.transform(t);
    if (costura >= 1) {
      _dibujar(canvas, capas.hilo);
    } else if (costura > 0) {
      final medida = _recorridoHilo.computeMetrics().first;
      final recorrido = medida.length * costura;
      canvas.saveLayer(Offset.zero & const Size(_ancho, 563), Paint());
      _dibujar(canvas, capas.hilo);
      canvas
        ..drawPath(
          medida.extractPath(0, recorrido),
          Paint()
            ..blendMode = BlendMode.dstIn
            ..style = PaintingStyle.stroke
            ..strokeWidth = 22
            ..strokeCap = StrokeCap.round,
        )
        ..restore();
      final punta = medida.getTangentForOffset(recorrido)?.position;
      if (punta != null) {
        canvas.drawCircle(
          punta,
          9,
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85 * math.sin(math.pi * costura))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }

    // 4. Nombre y lema: suben un poco mientras aparecen.
    final texto = _texto.transform(t);
    if (texto > 0) _dibujar(canvas, capas.texto, opacidad: texto, desplazamiento: Offset(0, 22 * (1 - texto)));
    final lema = _lema.transform(t);
    if (lema > 0) _dibujar(canvas, capas.lema, opacidad: lema, desplazamiento: Offset(0, 12 * (1 - lema)));

    canvas.restore();
  }

  void _dibujar(Canvas canvas, ui.Image imagen, {double opacidad = 1, Offset desplazamiento = Offset.zero}) {
    canvas.drawImage(
      imagen,
      desplazamiento,
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: opacidad)
        ..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(PintorLogoAnimado anterior) => anterior.capas != capas || anterior.avance != avance;
}
