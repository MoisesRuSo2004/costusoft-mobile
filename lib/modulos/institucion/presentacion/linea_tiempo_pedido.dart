import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../pedidos/presentacion/estilos_pedidos.dart';
import '../dominio/seguimiento_pedido.dart';

/// Línea de tiempo vertical del pedido: los hitos alcanzados con su fecha,
/// el actual resaltado (late suavemente) y los que faltan en gris.
class LineaTiempoPedido extends StatelessWidget {
  const LineaTiempoPedido({super.key, required this.hitos, required this.acento});

  final List<HitoPedido> hitos;

  /// Color del rol para los hitos completados.
  final Color acento;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < hitos.length; i++)
          _FilaHito(
            hito: hitos[i],
            acento: acento,
            esUltimo: i == hitos.length - 1,
            // El tramo hacia el siguiente hito se pinta si ese hito ya se alcanzó.
            tramoCompleto: i < hitos.length - 1 && hitos[i + 1].situacion != SituacionHito.pendiente,
          ),
      ],
    );
  }
}

class _FilaHito extends StatelessWidget {
  const _FilaHito({required this.hito, required this.acento, required this.esUltimo, required this.tramoCompleto});

  final HitoPedido hito;
  final Color acento;
  final bool esUltimo;
  final bool tramoCompleto;

  @override
  Widget build(BuildContext context) {
    final pendiente = hito.situacion == SituacionHito.pendiente;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _Nodo(hito: hito, acento: acento),
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: tramoCompleto ? acento : ColoresApp.borde,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: esUltimo ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hito.titulo,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: hito.situacion == SituacionHito.actual ? FontWeight.w700 : FontWeight.w600,
                            color: pendiente ? ColoresApp.textoTenue : ColoresApp.textoTitulo,
                          ),
                        ),
                      ),
                      if (hito.fecha != null)
                        Text(
                          Formatos.fecha(hito.fecha!),
                          style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hito.descripcion,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: switch (hito.situacion) {
                        SituacionHito.pendiente => ColoresApp.textoTenue,
                        SituacionHito.cancelado => ColoresApp.error,
                        _ => ColoresApp.textoSecundario,
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo del hito: check (completado), punto que late (actual),
/// aro gris (pendiente) o equis roja (cancelado).
class _Nodo extends StatelessWidget {
  const _Nodo({required this.hito, required this.acento});

  final HitoPedido hito;
  final Color acento;

  static const _tamano = 28.0;

  @override
  Widget build(BuildContext context) {
    return switch (hito.situacion) {
      SituacionHito.completado => _circulo(acento, const Icon(Icons.check_rounded, size: 16, color: Colors.white)),
      SituacionHito.cancelado => _circulo(
        ColoresApp.error,
        const Icon(Icons.close_rounded, size: 16, color: Colors.white),
      ),
      SituacionHito.actual => _NodoActual(color: hito.estado.color, icono: hito.estado.icono),
      SituacionHito.pendiente => Container(
        width: _tamano,
        height: _tamano,
        decoration: BoxDecoration(
          color: ColoresApp.fondo,
          shape: BoxShape.circle,
          border: Border.all(color: ColoresApp.bordeFuerte, width: 2),
        ),
      ),
    };
  }

  Widget _circulo(Color color, Widget icono) => Container(
    width: _tamano,
    height: _tamano,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: icono,
  );
}

class _NodoActual extends StatefulWidget {
  const _NodoActual({required this.color, required this.icono});

  final Color color;
  final IconData icono;

  @override
  State<_NodoActual> createState() => _EstadoNodoActual();
}

class _EstadoNodoActual extends State<_NodoActual> with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _latido.stop();
    } else if (!_latido.isAnimating) {
      _latido.repeat();
    }
  }

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _Nodo._tamano,
      height: _Nodo._tamano,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _latido,
            builder: (_, _) {
              final t = Curves.easeOut.transform(_latido.value);
              return Container(
                width: _Nodo._tamano * (1 + 0.6 * t),
                height: _Nodo._tamano * (1 + 0.6 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                ),
              );
            },
          ),
          Container(
            width: _Nodo._tamano,
            height: _Nodo._tamano,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
            child: Icon(widget.icono, size: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
