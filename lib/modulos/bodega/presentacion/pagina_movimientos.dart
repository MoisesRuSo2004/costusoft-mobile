import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../dominio/movimiento.dart';
import 'proveedores_bodega.dart';
import 'tarjeta_movimiento.dart';

/// Historial de entradas y salidas (paginado en el servidor).
class PaginaMovimientos extends ConsumerStatefulWidget {
  const PaginaMovimientos({super.key});

  @override
  ConsumerState<PaginaMovimientos> createState() => _EstadoPaginaMovimientos();
}

class _EstadoPaginaMovimientos extends ConsumerState<PaginaMovimientos> {
  final _desplazamiento = ScrollController();

  @override
  void initState() {
    super.initState();
    _desplazamiento.addListener(() {
      final p = _desplazamiento.position;
      if (p.pixels >= p.maxScrollExtent - 400) ref.read(proveedorHistorialMovimientos.notifier).cargarMas();
    });
  }

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  Future<void> _actualizar() async {
    ref.invalidate(proveedorHistorialMovimientos);
    try {
      await ref.read(proveedorHistorialMovimientos.future);
    } on Object {
      // Se muestra en pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtro = ref.watch(proveedorFiltroMovimientos);
    final lista = ref.watch(proveedorHistorialMovimientos);
    final controladorFiltro = ref.read(proveedorFiltroMovimientos.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: RefreshIndicator(
        color: ColoresApp.verde,
        onRefresh: _actualizar,
        child: CustomScrollView(
          controller: _desplazamiento,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SegmentedButton<TipoMovimiento>(
                  segments: [
                    for (final tipo in TipoMovimiento.values)
                      ButtonSegment(value: tipo, label: Text(tipo.plural), icon: Icon(tipo.icono, size: 18)),
                  ],
                  selected: {filtro.tipo},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => controladorFiltro.elegirTipo(s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: filtro.tipo.color,
                    selectedForegroundColor: Colors.white,
                    side: const BorderSide(color: ColoresApp.borde),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  children: [
                    for (final (etiqueta, estado) in [
                      ('Todas', null),
                      ('Pendientes', EstadoMovimiento.pendiente),
                      ('Confirmadas', EstadoMovimiento.confirmada),
                      ('Rechazadas', EstadoMovimiento.rechazada),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(etiqueta),
                          selected: filtro.estado == estado,
                          showCheckmark: false,
                          selectedColor: ColoresApp.azulMarino,
                          backgroundColor: ColoresApp.fondo,
                          labelStyle: TextStyle(
                            color: filtro.estado == estado ? Colors.white : ColoresApp.textoEtiqueta,
                            fontSize: 13,
                          ),
                          side: BorderSide(color: filtro.estado == estado ? ColoresApp.azulMarino : ColoresApp.borde),
                          shape: const StadiumBorder(),
                          onSelected: (_) => controladorFiltro.elegirEstado(estado),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ...switch (lista) {
              AsyncValue(:final value?) when value.movimientos.isEmpty => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoVacio(
                    titulo: 'Sin movimientos',
                    mensaje: 'No hay movimientos con este filtro.',
                    icono: Icons.swap_vert_rounded,
                  ),
                ),
              ],
              AsyncValue(:final value?) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 16, 8),
                    child: Text(
                      '${Formatos.numero(value.total)} ${filtro.tipo.plural.toLowerCase()}'
                      ' · mostrando ${Formatos.numero(value.movimientos.length)}',
                      style: const TextStyle(fontSize: 13, color: ColoresApp.textoSecundario),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: value.movimientos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => TarjetaMovimiento(movimiento: value.movimientos[i]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Center(
                      child: value.cargandoMas
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                          : value.error != null
                          ? TextButton(
                              onPressed: ref.read(proveedorHistorialMovimientos.notifier).cargarMas,
                              child: const Text('Reintentar'),
                            )
                          : Text(
                              value.hayMas ? '' : 'No hay más movimientos',
                              style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoTenue),
                            ),
                    ),
                  ),
                ),
              ],
              AsyncError(:final error) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoError(
                    mensaje: error is Fallo ? error.mensaje : 'No se pudieron cargar los movimientos.',
                    alReintentar: _actualizar,
                  ),
                ),
              ],
              _ => [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => const BloqueEsqueleto(alto: 76, radio: 12),
                  ),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}
