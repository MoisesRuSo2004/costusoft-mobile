import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/rutas/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../autenticacion/dominio/rol_usuario.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../../ia/presentacion/proveedores_ia.dart';
import '../../tablero/presentacion/proveedores_tablero.dart';
import '../dominio/pedido.dart';
import 'estilos_pedidos.dart';
import 'proveedores_pedidos.dart';
import 'tarjeta_pedido.dart';

/// Pedidos de los colegios, con paginación en el servidor.
///
/// Con [estados] la lista se limita a esos estados (Bodega solo atiende
/// confirmados, en producción y listos) y abre en [estadoInicial].
class PaginaPedidos extends ConsumerStatefulWidget {
  const PaginaPedidos({super.key, this.estados, this.estadoInicial});

  final List<EstadoPedido>? estados;
  final EstadoPedido? estadoInicial;

  @override
  ConsumerState<PaginaPedidos> createState() => _EstadoPaginaPedidos();
}

class _EstadoPaginaPedidos extends ConsumerState<PaginaPedidos> {
  final _desplazamiento = ScrollController();

  @override
  void initState() {
    super.initState();
    _desplazamiento.addListener(_alDesplazar);
    final estados = widget.estados;
    if (estados != null) {
      // El filtro se cambia después del primer cuadro (no durante la construcción).
      Future.microtask(() {
        final controlador = ref.read(proveedorFiltroPedidos.notifier)..limpiar();
        controlador.elegirEstado(widget.estadoInicial ?? estados.first);
      });
    }
  }

  /// A 400 px del final se pide la siguiente página.
  void _alDesplazar() {
    final posicion = _desplazamiento.position;
    if (posicion.pixels >= posicion.maxScrollExtent - 400) {
      ref.read(proveedorListaPedidos.notifier).cargarMas();
    }
  }

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  Future<void> _actualizar() async {
    ref
      ..invalidate(proveedorListaPedidos)
      ..invalidate(proveedorConteoPedidos);
    try {
      await ref.read(proveedorListaPedidos.future);
    } on Object {
      // El error se muestra en pantalla.
    }
  }

  Future<void> _elegirColegio() async {
    final filtro = ref.read(proveedorFiltroPedidos);
    final elegido = await showModalBottomSheet<(int?, String?)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HojaColegios(seleccionado: filtro.colegioId),
    );
    if (elegido != null) ref.read(proveedorFiltroPedidos.notifier).elegirColegio(elegido.$1, elegido.$2);
  }

  @override
  Widget build(BuildContext context) {
    final lista = ref.watch(proveedorListaPedidos);
    final filtro = ref.watch(proveedorFiltroPedidos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          // `/api/colegios` no está disponible para Bodega.
          if (ref.watch(proveedorRolActual) != RolUsuario.bodega)
            IconButton(
              tooltip: 'Filtrar por colegio',
              onPressed: _elegirColegio,
              icon: Badge(
                isLabelVisible: filtro.colegioId != null,
                backgroundColor: ColoresApp.verde,
                smallSize: 8,
                child: const Icon(Icons.school_outlined),
              ),
            ),
          IconButton(tooltip: 'Actualizar', onPressed: _actualizar, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        color: ColoresApp.verde,
        onRefresh: _actualizar,
        child: CustomScrollView(
          controller: _desplazamiento,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _FiltroEstados(estados: widget.estados)),
            if (filtro.colegioId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      avatar: const Icon(Icons.school_rounded, size: 16, color: ColoresApp.azulMarino),
                      label: Text(filtro.nombreColegio ?? 'Colegio', overflow: TextOverflow.ellipsis),
                      onPressed: _elegirColegio,
                      onDeleted: () => ref.read(proveedorFiltroPedidos.notifier).elegirColegio(null, null),
                      backgroundColor: ColoresApp.infoFondo,
                      side: const BorderSide(color: ColoresApp.infoBorde),
                    ),
                  ),
                ),
              ),
            ...switch (lista) {
              AsyncValue(:final value?) => _contenido(value, filtro),
              AsyncError(:final error) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoError(
                    mensaje: error is Fallo ? error.mensaje : 'No se pudieron cargar los pedidos.',
                    alReintentar: _actualizar,
                  ),
                ),
              ],
              _ => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => const BloqueEsqueleto(alto: 104, radio: 12),
                  ),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _contenido(ListaPedidos lista, FiltroPedidos filtro) {
    if (lista.pedidos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              EstadoVacio(
                titulo: 'Sin pedidos',
                mensaje: filtro.estaActivo
                    ? 'No hay pedidos con estos filtros.'
                    : 'Los pedidos se crean desde la plataforma web o el portal de colegios.',
                icono: Icons.receipt_long_outlined,
              ),
              if (filtro.estaActivo)
                TextButton.icon(
                  onPressed: ref.read(proveedorFiltroPedidos.notifier).limpiar,
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
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
          child: Text(
            '${Formatos.numero(lista.total)} ${lista.total == 1 ? 'pedido' : 'pedidos'}'
            ' · mostrando ${Formatos.numero(lista.pedidos.length)}',
            style: const TextStyle(fontSize: 13, color: ColoresApp.textoSecundario),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: lista.pedidos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final pedido = lista.pedidos[i];
            return TarjetaPedido(
              pedido: pedido,
              alTocar: () => context.push(RutasApp.detallePedido(ref.read(proveedorRolActual), pedido.id)),
            );
          },
        ),
      ),
      SliverToBoxAdapter(child: _PieLista(lista: lista)),
    ];
  }
}

/// Indicador al final: cargando, error con reintento, o fin de la lista.
class _PieLista extends ConsumerWidget {
  const _PieLista({required this.lista});

  final ListaPedidos lista;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget contenido;
    if (lista.cargandoMas) {
      contenido = const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4));
    } else if (lista.errorAlCargarMas != null) {
      contenido = Column(
        children: [
          Text(lista.errorAlCargarMas!, style: const TextStyle(color: ColoresApp.error, fontSize: 13)),
          TextButton(onPressed: ref.read(proveedorListaPedidos.notifier).cargarMas, child: const Text('Reintentar')),
        ],
      );
    } else if (lista.hayMas) {
      contenido = TextButton(
        onPressed: ref.read(proveedorListaPedidos.notifier).cargarMas,
        child: const Text('Cargar más'),
      );
    } else {
      contenido = const Text('No hay más pedidos', style: TextStyle(fontSize: 12.5, color: ColoresApp.textoTenue));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Center(child: contenido),
    );
  }
}

/// Fichas por estado con la cantidad de pedidos en cada uno.
class _FiltroEstados extends ConsumerWidget {
  const _FiltroEstados({this.estados});

  /// Estados permitidos; `null` = todos, con la ficha "Todos".
  final List<EstadoPedido>? estados;

  static const _orden = [
    EstadoPedido.enProduccion,
    EstadoPedido.listoParaEntrega,
    EstadoPedido.confirmado,
    EstadoPedido.calculado,
    EstadoPedido.borrador,
    EstadoPedido.entregado,
    EstadoPedido.cancelado,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elegido = ref.watch(proveedorFiltroPedidos.select((f) => f.estado));
    final conteo = ref.watch(proveedorConteoPedidos).value;

    Widget ficha(String etiqueta, EstadoPedido? estado, int? cantidad) {
      final activa = elegido == estado;
      final color = estado?.color ?? ColoresApp.azulMarino;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          selected: activa,
          showCheckmark: false,
          label: Text(cantidad == null ? etiqueta : '$etiqueta · ${Formatos.numero(cantidad)}'),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: activa ? FontWeight.w600 : FontWeight.w500,
            color: activa ? Colors.white : ColoresApp.textoEtiqueta,
          ),
          selectedColor: color,
          backgroundColor: ColoresApp.fondo,
          side: BorderSide(color: activa ? color : ColoresApp.borde),
          shape: const StadiumBorder(),
          onSelected: (_) => ref.read(proveedorFiltroPedidos.notifier).elegirEstado(estado),
        ),
      );
    }

    final total = conteo?.porEstado.values.fold<int>(0, (a, b) => a + b);
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        children: [
          if (estados == null) ficha('Todos', null, total),
          for (final estado in estados ?? _orden) ficha(estado.etiqueta, estado, conteo?[estado]),
        ],
      ),
    );
  }
}

/// Lista de colegios para filtrar.
class _HojaColegios extends ConsumerWidget {
  const _HojaColegios({required this.seleccionado});

  final int? seleccionado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colegios = ref.watch(proveedorColegios);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [Text('Filtrar por colegio', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))],
              ),
            ),
            Flexible(
              child: switch (colegios) {
                AsyncValue(:final value?) => RadioGroup<int?>(
                  groupValue: seleccionado,
                  onChanged: (id) => Navigator.pop(context, (id, value.where((c) => c.id == id).firstOrNull?.nombre)),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const RadioListTile<int?>(
                        value: null,
                        title: Text('Todos los colegios'),
                        activeColor: ColoresApp.verde,
                      ),
                      for (final c in value)
                        RadioListTile<int?>(value: c.id, title: Text(c.nombre), activeColor: ColoresApp.verde),
                    ],
                  ),
                ),
                AsyncError(:final error) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(error is Fallo ? error.mensaje : 'No se pudieron cargar los colegios.'),
                ),
                _ => const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}
