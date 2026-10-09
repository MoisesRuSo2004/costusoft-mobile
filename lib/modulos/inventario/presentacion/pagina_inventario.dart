import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/rutas/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';
import 'proveedores_inventario.dart';
import 'tarjeta_insumo.dart';

/// Inventario: buscar, filtrar y, para Administrador y Usuario, ver el riesgo de IA.
/// Bodega lo usa en modo consulta.
class PaginaInventario extends ConsumerStatefulWidget {
  const PaginaInventario({super.key});

  @override
  ConsumerState<PaginaInventario> createState() => _EstadoPaginaInventario();
}

class _EstadoPaginaInventario extends ConsumerState<PaginaInventario> {
  late final _controladorBusqueda = TextEditingController(text: ref.read(proveedorFiltroInventario).texto);

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  Future<void> _actualizar() async {
    // El riesgo (lento) se recalcula en segundo plano; la lista se espera.
    ref.invalidate(proveedorPredicciones);
    try {
      ref.invalidate(proveedorInsumos);
      await ref.read(proveedorInsumos.future);
    } on Fallo catch (fallo) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fallo.mensaje)));
    }
  }

  void _limpiarFiltros() {
    _controladorBusqueda.clear();
    ref.read(proveedorFiltroInventario.notifier).limpiar();
  }

  @override
  Widget build(BuildContext context) {
    final insumos = ref.watch(proveedorInsumos);
    final filtrados = ref.watch(proveedorInsumosFiltrados);
    final riesgos = ref.watch(proveedorRiesgos);
    final veIa = ref.watch(proveedorVeAnalisisIa);
    final filtro = ref.watch(proveedorFiltroInventario);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [IconButton(tooltip: 'Actualizar', onPressed: _actualizar, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        color: ColoresApp.verde,
        onRefresh: _actualizar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _Buscador(
                  controlador: _controladorBusqueda,
                  alCambiar: ref.read(proveedorFiltroInventario.notifier).buscar,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _Resumen(insumos: insumos.value, riesgos: riesgos, filtro: filtro.rapido, veIa: veIa),
            ),
            const SliverToBoxAdapter(child: _FiltroTipos()),
            ...switch (filtrados) {
              AsyncValue(:final value?) => _resultados(value, insumos.value?.length ?? 0, riesgos, filtro),
              AsyncError(:final error) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoError(
                    mensaje: error is Fallo ? error.mensaje : 'Ocurrió un error inesperado.',
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
                    itemBuilder: (_, _) => const TarjetaInsumoEsqueleto(),
                  ),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _resultados(
    List<Insumo> lista,
    int total,
    AsyncValue<Map<int, NivelRiesgo>> riesgos,
    FiltroInventario filtro,
  ) {
    if (lista.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              EstadoVacio(
                titulo: total == 0 ? 'Aún no hay insumos' : 'Sin resultados',
                mensaje: total == 0
                    ? 'Los insumos se registran desde la plataforma web.'
                    : 'Ningún insumo coincide con la búsqueda o los filtros.',
                icono: total == 0 ? Icons.inventory_2_outlined : Icons.search_off_rounded,
              ),
              if (filtro.estaActivo)
                TextButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Quitar filtros'),
                ),
            ],
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
          child: Row(
            children: [
              Text(
                filtro.estaActivo ? 'Mostrando ${lista.length} de $total' : '$total insumos',
                style: const TextStyle(fontSize: 13, color: ColoresApp.textoSecundario),
              ),
              const Spacer(),
              if (filtro.estaActivo) TextButton(onPressed: _limpiarFiltros, child: const Text('Quitar filtros')),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.separated(
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, indice) {
            final insumo = lista[indice];
            return TarjetaInsumo(
              insumo: insumo,
              // Mientras carga: null (muestra "Analizando…"); si falló: sin indicador.
              riesgo: riesgos.hasValue
                  ? (riesgos.value![insumo.id] ?? NivelRiesgo.desconocido)
                  : (riesgos.hasError ? NivelRiesgo.desconocido : null),
              mostrarRiesgo: ref.read(proveedorVeAnalisisIa),
              alTocar: () => context.push(RutasApp.detalleInsumo(ref.read(proveedorRolActual), insumo.id)),
            );
          },
        ),
      ),
    ];
  }
}

class _Buscador extends StatefulWidget {
  const _Buscador({required this.controlador, required this.alCambiar});

  final TextEditingController controlador;
  final ValueChanged<String> alCambiar;

  @override
  State<_Buscador> createState() => _EstadoBuscador();
}

class _EstadoBuscador extends State<_Buscador> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controlador,
      onChanged: (texto) {
        widget.alCambiar(texto);
        setState(() {}); // Muestra u oculta el botón de borrar.
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o tipo',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: widget.controlador.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  widget.controlador.clear();
                  widget.alCambiar('');
                  setState(() {});
                },
              ),
      ),
    );
  }
}

/// Cuatro tarjetas de resumen; cada una filtra la lista al tocarla.
class _Resumen extends ConsumerWidget {
  const _Resumen({required this.insumos, required this.riesgos, required this.filtro, required this.veIa});

  final List<Insumo>? insumos;
  final AsyncValue<Map<int, NivelRiesgo>> riesgos;
  final FiltroRapido filtro;
  final bool veIa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = insumos;
    String contar(bool Function(Insumo) condicion) => lista == null ? '–' : '${lista.where(condicion).length}';
    final enRiesgo = riesgos.value?.values.where((n) => n.esPreocupante).length;
    void alternar(FiltroRapido f) => ref.read(proveedorFiltroInventario.notifier).alternarRapido(f);

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _TarjetaResumen(
            titulo: 'Total',
            valor: lista == null ? '–' : '${lista.length}',
            icono: Icons.inventory_2_rounded,
            color: ColoresApp.azulMarino,
            seleccionada: filtro == FiltroRapido.todos,
            alTocar: () => ref.read(proveedorFiltroInventario.notifier).alternarRapido(FiltroRapido.todos),
          ),
          _TarjetaResumen(
            titulo: 'Stock bajo',
            valor: contar((i) => i.estado == EstadoStock.stockBajo),
            icono: Icons.trending_down_rounded,
            color: ColoresApp.stockBajoTexto,
            seleccionada: filtro == FiltroRapido.stockBajo,
            alTocar: () => alternar(FiltroRapido.stockBajo),
          ),
          _TarjetaResumen(
            titulo: 'Sin stock',
            valor: contar((i) => i.estado == EstadoStock.sinStock),
            icono: Icons.remove_shopping_cart_rounded,
            color: ColoresApp.sinStockTexto,
            seleccionada: filtro == FiltroRapido.sinStock,
            alTocar: () => alternar(FiltroRapido.sinStock),
          ),
          if (veIa)
            _TarjetaResumen(
              titulo: 'En riesgo (IA)',
              valor: riesgos.hasError ? '!' : (enRiesgo == null ? null : '$enRiesgo'),
              icono: Icons.auto_awesome_rounded,
              color: ColoresApp.riesgoAlto,
              seleccionada: filtro == FiltroRapido.enRiesgo,
              alTocar: riesgos.hasValue ? () => alternar(FiltroRapido.enRiesgo) : null,
              ayuda: riesgos.hasError ? 'No se pudo calcular el riesgo' : null,
            ),
        ],
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.seleccionada,
    required this.alTocar,
    this.ayuda,
  });

  final String titulo;

  /// `null` = calculando (muestra un indicador de carga).
  final String? valor;
  final IconData icono;
  final Color color;
  final bool seleccionada;
  final VoidCallback? alTocar;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Tooltip(
        message: ayuda ?? '',
        child: Material(
          color: seleccionada ? color.withValues(alpha: 0.08) : ColoresApp.fondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: seleccionada ? color : ColoresApp.borde, width: seleccionada ? 1.5 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: alTocar,
            child: Container(
              width: 128,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icono, size: 18, color: color),
                      const Spacer(),
                      if (valor == null)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.8, color: color),
                        ),
                    ],
                  ),
                  Text(
                    valor ?? '…',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ColoresApp.textoTitulo),
                  ),
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fichas horizontales para filtrar por tipo de insumo.
class _FiltroTipos extends ConsumerWidget {
  const _FiltroTipos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipos = ref.watch(proveedorTiposInsumo);
    final tipoElegido = ref.watch(proveedorFiltroInventario.select((f) => f.tipo));
    if (tipos.isEmpty) return const SizedBox(height: 12);

    Widget ficha(String etiqueta, String? tipo) {
      final elegida = tipoElegido == tipo;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(etiqueta),
          selected: elegida,
          showCheckmark: false,
          selectedColor: ColoresApp.azulMarino,
          backgroundColor: ColoresApp.fondo,
          labelStyle: TextStyle(
            color: elegida ? Colors.white : ColoresApp.textoEtiqueta,
            fontWeight: elegida ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
          side: BorderSide(color: elegida ? ColoresApp.azulMarino : ColoresApp.borde),
          shape: const StadiumBorder(),
          onSelected: (_) => ref.read(proveedorFiltroInventario.notifier).elegirTipo(elegida ? null : tipo),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        children: [ficha('Todos', null), for (final (tipo, cantidad) in tipos) ficha('$tipo · $cantidad', tipo)],
      ),
    );
  }
}
