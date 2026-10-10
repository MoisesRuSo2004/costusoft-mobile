import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../compartido/widgets/encabezado_rol.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../compartido/widgets/tarjeta_avisos.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../../../nucleo/rutas/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/paleta_rol.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../pedidos/dominio/pedido.dart';
import '../../pedidos/presentacion/estilos_pedidos.dart';
import '../../pedidos/presentacion/tarjeta_pedido.dart';
import 'proveedores_bodega.dart';
import 'tarjeta_movimiento.dart';

/// Cola de trabajo de Bodega: movimientos por verificar y pedidos por atender.
class PaginaPendientes extends ConsumerWidget {
  const PaginaPendientes({super.key});

  static const _accionesPedido = {
    EstadoPedido.confirmado: 'Iniciar producción',
    EstadoPedido.enProduccion: 'Marcar como listos',
    EstadoPedido.listoParaEntrega: 'Entregar al colegio',
  };

  Future<void> _actualizar(WidgetRef ref) async {
    ref
      ..invalidate(proveedorMovimientosPendientes)
      ..invalidate(proveedorPedidosPorAtender);
    try {
      await Future.wait([ref.read(proveedorMovimientosPendientes.future), ref.read(proveedorPedidosPorAtender.future)]);
    } on Object {
      // Cada sección muestra su error.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientos = ref.watch(proveedorMovimientosPendientes);
    final pedidos = ref.watch(proveedorPedidosPorAtender);

    return Scaffold(
      backgroundColor: ColoresApp.fondoSuave,
      body: RefreshIndicator(
        color: PaletaRol.bodega.acento,
        onRefresh: () => _actualizar(ref),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _Encabezado(movimientos: movimientos.value, pedidos: pedidos.value),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // "Activa los avisos": te llega cada entrada o salida nueva.
                  const TarjetaAvisos(),
                  const _Titulo(
                    texto: 'Por verificar',
                    detalle: 'Entradas y salidas registradas que esperan tu confirmación',
                  ),
                  switch (movimientos) {
                    AsyncValue(:final value?) when value.total == 0 => const _TodoAlDia(
                      texto: 'No hay entradas ni salidas pendientes.',
                    ),
                    AsyncValue(:final value?) => Column(
                      children: [
                        for (final m in [...value.entradas, ...value.salidas])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TarjetaMovimiento(movimiento: m),
                          ),
                      ],
                    ),
                    AsyncError(:final error) => EstadoError(
                      mensaje: error is Fallo ? error.mensaje : 'No se pudieron cargar los pendientes.',
                      alReintentar: () => ref.invalidate(proveedorMovimientosPendientes),
                    ),
                    _ => const Column(
                      children: [
                        BloqueEsqueleto(alto: 76, radio: 12),
                        SizedBox(height: 10),
                        BloqueEsqueleto(alto: 76, radio: 12),
                      ],
                    ),
                  },
                  const SizedBox(height: 20),
                  const _Titulo(texto: 'Pedidos por atender', detalle: 'Producción, alistamiento y entrega'),
                  switch (pedidos) {
                    AsyncValue(:final value?) when value.values.every((p) => p.totalElementos == 0) => const _TodoAlDia(
                      texto: 'No hay pedidos por atender.',
                    ),
                    AsyncValue(:final value?) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final estado in estadosPedidoBodega)
                          if (value[estado]!.totalElementos > 0) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                              child: Row(
                                children: [
                                  Icon(estado.icono, size: 16, color: estado.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${estado.etiqueta} · ${Formatos.numero(value[estado]!.totalElementos)}',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: estado.color, fontSize: 13.5),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _accionesPedido[estado]!,
                                    style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                                  ),
                                ],
                              ),
                            ),
                            for (final p in value[estado]!.contenido)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TarjetaPedido(
                                  pedido: p,
                                  alTocar: () => context.push(RutasApp.bodegaDetallePedido(p.id)),
                                ),
                              ),
                            if (value[estado]!.totalElementos > value[estado]!.contenido.length)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => context.push('${RutasApp.bodegaPedidos}?estado=${estado.codigo}'),
                                  iconAlignment: IconAlignment.end,
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  label: Text('Ver los ${Formatos.numero(value[estado]!.totalElementos)}'),
                                ),
                              ),
                            const SizedBox(height: 6),
                          ],
                      ],
                    ),
                    AsyncError(:final error) => EstadoError(
                      mensaje: error is Fallo ? error.mensaje : 'No se pudieron cargar los pedidos.',
                      alReintentar: () => ref.invalidate(proveedorPedidosPorAtender),
                    ),
                    _ => const Column(
                      children: [
                        BloqueEsqueleto(alto: 104, radio: 12),
                        SizedBox(height: 10),
                        BloqueEsqueleto(alto: 104, radio: 12),
                      ],
                    ),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado verde de Bodega: cuántas tareas hay en la cola y su desglose
/// (las cuatro cifras suman el total del chip).
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.movimientos, required this.pedidos});

  final MovimientosPendientes? movimientos;
  final Map<EstadoPedido, PaginaApi<Pedido>>? pedidos;

  @override
  Widget build(BuildContext context) {
    final m = movimientos;
    final p = pedidos;
    int? pedidosEn(EstadoPedido e) => p?[e]?.totalElementos;
    final tareas = m == null || p == null
        ? null
        : m.total + estadosPedidoBodega.fold<int>(0, (suma, e) => suma + (pedidosEn(e) ?? 0));

    return EncabezadoRol(
      estado: switch (tareas) {
        null => const ChipEncabezado.cargando(texto: 'Revisando la cola de trabajo…'),
        0 => const ChipEncabezado(
          icono: Icons.check_circle_outline_rounded,
          colorIcono: ColoresApp.verdeClaro,
          texto: 'Todo al día',
        ),
        _ => ChipEncabezado(
          icono: Icons.pending_actions_rounded,
          colorIcono: ChipEncabezado.colorAlerta,
          texto: tareas == 1 ? '1 tarea en la cola' : '${Formatos.numero(tareas)} tareas en la cola',
        ),
      },
      cifras: [
        CifraEncabezado(valor: m?.total, etiqueta: 'Por verificar'),
        CifraEncabezado(valor: pedidosEn(EstadoPedido.confirmado), etiqueta: 'Producir'),
        CifraEncabezado(valor: pedidosEn(EstadoPedido.enProduccion), etiqueta: 'En producción'),
        CifraEncabezado(valor: pedidosEn(EstadoPedido.listoParaEntrega), etiqueta: 'Entregar'),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.texto, required this.detalle});

  final String texto;
  final String detalle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(detalle, style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario)),
      ],
    ),
  );
}

class _TodoAlDia extends StatelessWidget {
  const _TodoAlDia({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ColoresApp.disponibleFondo,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: Row(
      children: [
        const Icon(Icons.task_alt_rounded, color: ColoresApp.disponibleTexto),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Todo está al día. $texto',
            style: const TextStyle(color: ColoresApp.disponibleTexto, fontSize: 13.5),
          ),
        ),
      ],
    ),
  );
}
