import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/encabezado_rol.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/paleta_rol.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../pedidos/dominio/pedido.dart';
import '../../pedidos/presentacion/estilos_pedidos.dart';
import '../dominio/seguimiento_pedido.dart';
import 'linea_tiempo_pedido.dart';
import 'proveedores_institucion.dart';

/// Seguimiento de un pedido para el colegio: en qué va, cuándo pasó cada
/// cosa y qué prendas incluye. Sin datos internos del taller (insumos,
/// cálculos ni quién hizo cada cambio).
class PaginaSeguimientoPedido extends ConsumerWidget {
  const PaginaSeguimientoPedido({super.key, required this.pedidoId});

  final int pedidoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedido = ref.watch(proveedorPedidoInstitucion(pedidoId));
    final acento = ref.watch(proveedorPaletaRol).acento;

    Future<void> actualizar() async {
      ref
        ..invalidate(proveedorPedidoInstitucion(pedidoId))
        ..invalidate(proveedorHistorialInstitucion(pedidoId));
      try {
        await ref.read(proveedorPedidoInstitucion(pedidoId).future);
      } on Object {
        // Se muestra en pantalla.
      }
    }

    return Scaffold(
      backgroundColor: ColoresApp.fondoSuave,
      body: switch (pedido) {
        AsyncValue(:final value?) => RefreshIndicator(
          color: acento,
          onRefresh: actualizar,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              _Portada(pedido: value),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Seccion(
                      titulo: 'Seguimiento',
                      icono: Icons.timeline_rounded,
                      child: _Seguimiento(pedido: value, acento: acento),
                    ),
                    const SizedBox(height: 14),
                    _Seccion(
                      titulo: 'Prendas · ${Formatos.numero(value.totalPrendas)}',
                      icono: Icons.checkroom_rounded,
                      child: _Prendas(pedido: value),
                    ),
                    if (value.observaciones case final observaciones?) ...[
                      const SizedBox(height: 14),
                      _Seccion(
                        titulo: 'Observaciones',
                        icono: Icons.notes_rounded,
                        child: Text(
                          observaciones,
                          style: const TextStyle(fontSize: 13.5, color: ColoresApp.textoEtiqueta, height: 1.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        AsyncError(:final error) => SafeArea(
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: BackButton()),
              Expanded(
                child: EstadoError(
                  mensaje: error is Fallo ? error.mensaje : 'No se pudo cargar el pedido.',
                  alReintentar: actualizar,
                ),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Portada con el color del rol: número, estado, frase y fecha estimada.
class _Portada extends StatelessWidget {
  const _Portada({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final dias = pedido.diasParaEntrega(hoy);
    final fecha = pedido.fechaEntregaEstimada;
    final textoEntrega = switch ((fecha, dias)) {
      (null, _) || (_, null) => null,
      // Ya listo o finalizado, el plazo deja de importar.
      _ when pedido.estado.esFinal || pedido.estado == EstadoPedido.listoParaEntrega =>
        'Fecha estimada: ${Formatos.fecha(fecha!)}',
      (_, 0) => 'Entrega estimada: hoy',
      (_, final d?) when d > 0 => 'Entrega estimada: ${Formatos.fecha(fecha!)} · en ${Formatos.dias(d)}',
      _ => 'La fecha estimada era el ${Formatos.fecha(fecha!)}',
    };

    return FondoRol(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(color: Colors.white),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pedido.numero,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        _InsigniaEstado(estado: pedido.estado),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      mensajeDeSeguimiento(pedido.estado),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    if (textoEntrega != null) ...[
                      const SizedBox(height: 12),
                      ChipEncabezado(icono: Icons.event_outlined, colorIcono: Colors.white70, texto: textoEntrega),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado en una píldora blanca, legible sobre cualquier degradado.
class _InsigniaEstado extends StatelessWidget {
  const _InsigniaEstado({required this.estado});

  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estado.icono, size: 14, color: estado.color),
          const SizedBox(width: 5),
          Text(
            estado.etiqueta,
            style: TextStyle(color: estado.color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono, required this.child});

  final String titulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: ColoresApp.textoSecundario),
              const SizedBox(width: 8),
              Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _Seguimiento extends ConsumerWidget {
  const _Seguimiento({required this.pedido, required this.acento});

  final Pedido pedido;
  final Color acento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historial = ref.watch(proveedorHistorialInstitucion(pedido.id));
    return switch (historial) {
      // Sin historial igual se muestra la línea con el estado actual.
      AsyncValue(:final value?) => LineaTiempoPedido(hitos: calcularHitos(pedido, value), acento: acento),
      AsyncError() => LineaTiempoPedido(hitos: calcularHitos(pedido, const []), acento: acento),
      _ => const Column(children: [BloqueEsqueleto(alto: 44), SizedBox(height: 10), BloqueEsqueleto(alto: 44)]),
    };
  }
}

class _Prendas extends StatelessWidget {
  const _Prendas({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    if (pedido.prendas.isEmpty) {
      return const Text('Sin prendas registradas.', style: TextStyle(color: ColoresApp.textoSecundario));
    }
    return Column(
      children: [
        for (var i = 0; i < pedido.prendas.length; i++) ...[
          if (i > 0) const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pedido.prendas[i].uniforme, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      [
                        pedido.prendas[i].tipo,
                        if (pedido.prendas[i].talla != null) 'Talla ${pedido.prendas[i].talla}',
                        pedido.prendas[i].genero,
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
                    ),
                  ],
                ),
              ),
              Text(
                '× ${Formatos.numero(pedido.prendas[i].cantidad)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
