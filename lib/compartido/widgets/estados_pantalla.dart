import 'package:flutter/material.dart';

import '../../nucleo/tema/colores_app.dart';

/// Mensaje de error con botón para reintentar.
class EstadoError extends StatelessWidget {
  const EstadoError({super.key, required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icono: Icons.cloud_off_rounded,
      colorIcono: ColoresApp.error,
      fondoIcono: ColoresApp.errorFondo,
      titulo: 'No pudimos cargar la información',
      mensaje: mensaje,
      accion: OutlinedButton.icon(
        onPressed: alReintentar,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      ),
    );
  }
}

/// Lista vacía o búsqueda sin resultados.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.titulo, required this.mensaje, this.icono = Icons.search_off_rounded});

  final String titulo;
  final String mensaje;
  final IconData icono;

  @override
  Widget build(BuildContext context) => _EstadoBase(
    icono: icono,
    colorIcono: ColoresApp.textoTenue,
    fondoIcono: ColoresApp.fondoSuave,
    titulo: titulo,
    mensaje: mensaje,
  );
}

class _EstadoBase extends StatelessWidget {
  const _EstadoBase({
    required this.icono,
    required this.colorIcono,
    required this.fondoIcono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final Color colorIcono;
  final Color fondoIcono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: fondoIcono, shape: BoxShape.circle),
            child: Icon(icono, size: 32, color: colorIcono),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: ColoresApp.textoSecundario, height: 1.4),
          ),
          if (accion != null) ...[const SizedBox(height: 20), accion!],
        ],
      ),
    );
  }
}

/// Bloque gris que ocupa el lugar del contenido mientras carga.
class BloqueEsqueleto extends StatefulWidget {
  const BloqueEsqueleto({super.key, this.ancho, required this.alto, this.radio = 8});

  final double? ancho;
  final double alto;
  final double radio;

  @override
  State<BloqueEsqueleto> createState() => _EstadoBloqueEsqueleto();
}

class _EstadoBloqueEsqueleto extends State<BloqueEsqueleto> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulso),
      child: Container(
        width: widget.ancho,
        height: widget.alto,
        decoration: BoxDecoration(color: const Color(0xFFEEF0F3), borderRadius: BorderRadius.circular(widget.radio)),
      ),
    );
  }
}

/// Etiqueta pequeña con punto de color (estado, riesgo, etc.).
/// "Por enviar": el cambio está en la bandeja de salida.
class InsigniaPorEnviar extends StatelessWidget {
  const InsigniaPorEnviar({super.key});

  @override
  Widget build(BuildContext context) => const Insignia(
    texto: 'Por enviar',
    fondo: ColoresApp.infoFondo,
    color: ColoresApp.azulMedio,
    punto: ColoresApp.azulMedio,
  );
}

class Insignia extends StatelessWidget {
  const Insignia({super.key, required this.texto, required this.fondo, required this.color, this.punto});

  final String texto;
  final Color fondo;
  final Color color;
  final Color? punto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (punto != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: punto, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            texto,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
