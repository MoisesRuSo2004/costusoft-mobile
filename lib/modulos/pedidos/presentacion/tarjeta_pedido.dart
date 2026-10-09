import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../dominio/pedido.dart';
import 'estilos_pedidos.dart';

/// Tarjeta de un pedido en la lista.
class TarjetaPedido extends StatelessWidget {
  const TarjetaPedido({super.key, required this.pedido, required this.alTocar, this.mostrarColegio = true});

  final Pedido pedido;
  final VoidCallback alTocar;

  /// En el portal del colegio todos los pedidos son del mismo colegio.
  final bool mostrarColegio;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final estado = pedido.estado;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja con el color del estado.
              Container(width: 4, color: estado.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pedido.numero,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: ColoresApp.textoTitulo,
                              ),
                            ),
                          ),
                          estado.insignia,
                        ],
                      ),
                      if (mostrarColegio) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 15, color: ColoresApp.textoTenue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pedido.colegio.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: ColoresApp.textoEtiqueta),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _Dato(
                            icono: Icons.checkroom_outlined,
                            texto:
                                '${Formatos.numero(pedido.totalPrendas)} '
                                '${pedido.totalPrendas == 1 ? 'prenda' : 'prendas'}',
                          ),
                          if (pedido.fechaCreacion != null)
                            _Dato(icono: Icons.event_outlined, texto: Formatos.fecha(pedido.fechaCreacion!)),
                          if (pedido.fechaEntregaEstimada != null && !estado.esFinal)
                            _EntregaEstimada(pedido: pedido, hoy: hoy),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto, this.color = ColoresApp.textoSecundario});

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 14, color: color),
      const SizedBox(width: 4),
      Text(texto, style: TextStyle(fontSize: 12.5, color: color)),
    ],
  );
}

/// "Entrega en 5 días", "Entrega hoy" o "Atrasado 3 días".
class _EntregaEstimada extends StatelessWidget {
  const _EntregaEstimada({required this.pedido, required this.hoy});

  final Pedido pedido;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final dias = pedido.diasParaEntrega(hoy)!;
    final (texto, color) = switch (dias) {
      < 0 => ('Atrasado ${Formatos.dias(-dias)}', ColoresApp.error),
      0 => ('Entrega hoy', ColoresApp.stockBajoTexto),
      <= 3 => ('Entrega en ${Formatos.dias(dias)}', ColoresApp.stockBajoTexto),
      _ => ('Entrega ${Formatos.fecha(pedido.fechaEntregaEstimada!)}', ColoresApp.textoSecundario),
    };
    return _Dato(icono: Icons.local_shipping_outlined, texto: texto, color: color);
  }
}
