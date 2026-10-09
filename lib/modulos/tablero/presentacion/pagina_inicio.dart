import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../compartido/widgets/encabezado_rol.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/rutas/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../inventario/presentacion/proveedores_inventario.dart';
import '../dominio/resumen_tablero.dart';
import 'graficas_tablero.dart';
import 'proveedores_tablero.dart';

/// Inicio del administrador: lo que requiere atención hoy, pedidos en curso,
/// movimientos del almacén y totales del sistema.
class PaginaInicio extends ConsumerWidget {
  const PaginaInicio({super.key});

  Future<void> _actualizar(WidgetRef ref) async {
    ref
      ..invalidate(proveedorResumenTablero)
      ..invalidate(proveedorConteoPedidos)
      ..invalidate(proveedorPredicciones);
    try {
      await Future.wait([ref.read(proveedorResumenTablero.future), ref.read(proveedorConteoPedidos.future)]);
    } on Object {
      // Cada sección muestra su propio error.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(proveedorResumenTablero);
    final pedidos = ref.watch(proveedorConteoPedidos);

    return Scaffold(
      backgroundColor: ColoresApp.fondoSuave,
      body: RefreshIndicator(
        color: ColoresApp.verde,
        onRefresh: () => _actualizar(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Encabezado(resumen: resumen.value)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              sliver: SliverList.list(
                children: [
                  if (resumen case AsyncError(:final error))
                    EstadoError(
                      mensaje: error is Fallo ? error.mensaje : 'No se pudo cargar el resumen.',
                      alReintentar: () => _actualizar(ref),
                    )
                  else ...[
                    const _Titulo('Requiere tu atención'),
                    _Atencion(resumen: resumen.value, pedidos: pedidos.value),
                    const SizedBox(height: 24),
                    const _Titulo('Pedidos en curso'),
                    _TarjetaPedidos(pedidos: pedidos),
                    const SizedBox(height: 24),
                    const _Titulo('Movimientos del almacén'),
                    _TarjetaMovimientos(resumen: resumen.value),
                    const SizedBox(height: 24),
                    const _Titulo('Últimos movimientos'),
                    _UltimosMovimientos(resumen: resumen.value),
                    const SizedBox(height: 24),
                    const _Titulo('Totales del sistema'),
                    _Totales(resumen: resumen.value),
                    const SizedBox(height: 24),
                    const _AccesoAsistente(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Encabezado ────────────────────────────────────────────────────────────

/// Encabezado con el color del rol (Administrador o Secretaría) y el estado
/// del inventario.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.resumen});

  final ResumenTablero? resumen;

  @override
  Widget build(BuildContext context) {
    final r = resumen;
    final hayAlertas = r != null && (r.insumosConStockBajo > 0 || r.insumosSinStock > 0);
    return EncabezadoRol(
      estado: switch (r) {
        null => const ChipEncabezado.cargando(texto: 'Revisando el taller…'),
        _ when hayAlertas => const ChipEncabezado(
          icono: Icons.error_outline_rounded,
          colorIcono: ChipEncabezado.colorAlerta,
          texto: 'Inventario con alertas',
        ),
        _ => const ChipEncabezado(
          icono: Icons.check_circle_outline_rounded,
          colorIcono: ColoresApp.verdeClaro,
          texto: 'Todo en orden',
        ),
      },
      cifras: [
        CifraEncabezado(valor: r?.totalInsumos, etiqueta: 'Insumos'),
        CifraEncabezado(valor: r?.insumosSoloStockBajo, etiqueta: 'Stock bajo'),
        CifraEncabezado(valor: r?.insumosSinStock, etiqueta: 'Sin stock'),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
    ),
  );
}

// ── Requiere tu atención ──────────────────────────────────────────────────

class _Atencion extends ConsumerWidget {
  const _Atencion({required this.resumen, required this.pedidos});

  final ResumenTablero? resumen;
  final ConteoPedidos? pedidos;

  void _abrirInventario(BuildContext context, WidgetRef ref, FiltroRapido filtro) {
    ref.read(proveedorFiltroInventario.notifier).aplicarSolo(filtro);
    context.go(RutasApp.adminInventario);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = resumen;
    final riesgos = ref.watch(proveedorRiesgos);
    final enRiesgo = riesgos.value?.values.where((n) => n.esPreocupante).length;

    return Card(
      child: Column(
        children: [
          _ItemAtencion(
            icono: Icons.local_shipping_outlined,
            color: ColoresApp.verde,
            titulo: 'Pedidos listos para entregar',
            detalle: 'Coordina la entrega con los colegios',
            valor: pedidos?[EstadoPedido.listoParaEntrega],
            alTocar: () => context.go(RutasApp.adminPedidos),
          ),
          const Divider(height: 1, indent: 64),
          _ItemAtencion(
            icono: Icons.remove_shopping_cart_outlined,
            color: ColoresApp.sinStockTexto,
            titulo: 'Insumos sin stock',
            detalle: 'Detienen la producción',
            valor: r?.insumosSinStock,
            alTocar: () => _abrirInventario(context, ref, FiltroRapido.sinStock),
          ),
          const Divider(height: 1, indent: 64),
          _ItemAtencion(
            icono: Icons.trending_down_rounded,
            color: ColoresApp.stockBajoTexto,
            titulo: 'Insumos con stock bajo',
            detalle: 'Por debajo del mínimo definido',
            valor: r?.insumosSoloStockBajo,
            alTocar: () => _abrirInventario(context, ref, FiltroRapido.stockBajo),
          ),
          const Divider(height: 1, indent: 64),
          _ItemAtencion(
            icono: Icons.auto_awesome_rounded,
            color: ColoresApp.riesgoAlto,
            titulo: 'En riesgo según la IA',
            detalle: 'Riesgo alto o crítico de agotarse',
            valor: enRiesgo,
            cargando: riesgos.isLoading && enRiesgo == null,
            alTocar: () => _abrirInventario(context, ref, FiltroRapido.enRiesgo),
          ),
        ],
      ),
    );
  }
}

class _ItemAtencion extends StatelessWidget {
  const _ItemAtencion({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.valor,
    required this.alTocar,
    this.cargando = false,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final int? valor;
  final VoidCallback alTocar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final cantidad = valor;
    final activo = (cantidad ?? 0) > 0;
    return InkWell(
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(detalle, style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario)),
                ],
              ),
            ),
            if (cantidad == null)
              cargando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const BloqueEsqueleto(ancho: 28, alto: 22, radio: 99)
            else
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activo ? color : ColoresApp.fondoSuave,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  Formatos.numero(cantidad),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: activo ? Colors.white : ColoresApp.textoTenue,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: ColoresApp.textoTenue),
          ],
        ),
      ),
    );
  }
}

// ── Pedidos en curso ──────────────────────────────────────────────────────

class _TarjetaPedidos extends StatelessWidget {
  const _TarjetaPedidos({required this.pedidos});

  final AsyncValue<ConteoPedidos> pedidos;

  static const _etapas = [
    (EstadoPedido.confirmado, Icons.task_alt_rounded),
    (EstadoPedido.enProduccion, Icons.precision_manufacturing_outlined),
    (EstadoPedido.listoParaEntrega, Icons.inventory_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (pedidos) {
          AsyncValue(:final value?) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // Alineadas arriba: así los círculos quedan parejos aunque una
                // etiqueta ocupe dos líneas ("Listo para entrega").
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _etapas.length; i++) ...[
                    Expanded(
                      child: _Etapa(
                        etiqueta: _etapas[i].$1.etiqueta,
                        icono: _etapas[i].$2,
                        cantidad: value[_etapas[i].$1],
                      ),
                    ),
                    if (i < _etapas.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(top: 9),
                        child: Icon(Icons.chevron_right_rounded, color: ColoresApp.bordeFuerte),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              if (value.tasaCumplimiento case final tasa?) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tasa de cumplimiento',
                        style: TextStyle(fontSize: 13, color: ColoresApp.textoSecundario),
                      ),
                    ),
                    Text(
                      '${Formatos.numero(double.parse(tasa.toStringAsFixed(1)))} %',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: ColoresApp.verde),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: tasa / 100,
                    minHeight: 8,
                    backgroundColor: ColoresApp.sinStockFondo,
                    color: ColoresApp.verde,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${Formatos.numero(value[EstadoPedido.entregado])} entregados · '
                  '${Formatos.numero(value[EstadoPedido.cancelado])} cancelados',
                  style: const TextStyle(fontSize: 12, color: ColoresApp.textoTenue),
                ),
              ],
            ],
          ),
          AsyncError(:final error) => Text(
            error is Fallo ? error.mensaje : 'No se pudieron contar los pedidos.',
            style: const TextStyle(color: ColoresApp.error),
          ),
          _ => const Column(
            children: [
              BloqueEsqueleto(alto: 70, radio: 12),
              SizedBox(height: 16),
              BloqueEsqueleto(alto: 12, radio: 99),
            ],
          ),
        },
      ),
    );
  }
}

class _Etapa extends StatelessWidget {
  const _Etapa({required this.etiqueta, required this.icono, required this.cantidad});

  final String etiqueta;
  final IconData icono;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final activa = cantidad > 0;
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: activa ? ColoresApp.azulMarino : ColoresApp.fondoSuave,
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 20, color: activa ? Colors.white : ColoresApp.textoTenue),
        ),
        const SizedBox(height: 8),
        Text(
          Formatos.numero(cantidad),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: activa ? ColoresApp.textoTitulo : ColoresApp.textoTenue,
          ),
        ),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoSecundario, height: 1.2),
        ),
      ],
    );
  }
}

// ── Movimientos ───────────────────────────────────────────────────────────

class _TarjetaMovimientos extends StatelessWidget {
  const _TarjetaMovimientos({required this.resumen});

  final ResumenTablero? resumen;

  @override
  Widget build(BuildContext context) {
    final r = resumen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: r == null
            ? const BloqueEsqueleto(alto: 190, radio: 12)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      _Leyenda(color: ColoresApp.verde, texto: 'Entradas'),
                      SizedBox(width: 16),
                      _Leyenda(color: ColoresApp.azulMarino, texto: 'Salidas'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GraficaMovimientosMensuales(meses: r.movimientosPorMes),
                ],
              ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(texto, style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario)),
    ],
  );
}

class _UltimosMovimientos extends StatelessWidget {
  const _UltimosMovimientos({required this.resumen});

  final ResumenTablero? resumen;

  @override
  Widget build(BuildContext context) {
    final movimientos = resumen?.ultimosMovimientos;
    if (movimientos == null) return const BloqueEsqueleto(alto: 180, radio: 14);
    if (movimientos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aún no hay movimientos.', style: TextStyle(color: ColoresApp.textoSecundario)),
        ),
      );
    }
    final visibles = movimientos.take(5).toList();
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < visibles.length; i++) ...[
            _FilaMovimiento(movimiento: visibles[i]),
            if (i < visibles.length - 1) const Divider(height: 1, indent: 64),
          ],
        ],
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento({required this.movimiento});

  final MovimientoReciente movimiento;

  @override
  Widget build(BuildContext context) {
    final esEntrada = movimiento.tipo == TipoMovimiento.entrada;
    final color = esEntrada ? ColoresApp.verde : ColoresApp.azulMarino;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(esEntrada ? Icons.south_west_rounded : Icons.north_east_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.descripcion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${esEntrada ? 'Entrada' : 'Salida'} · ${movimiento.totalItems} '
                  '${movimiento.totalItems == 1 ? 'insumo' : 'insumos'}',
                  style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                ),
              ],
            ),
          ),
          if (movimiento.fecha != null)
            Text(Formatos.fecha(movimiento.fecha!), style: const TextStyle(fontSize: 12, color: ColoresApp.textoTenue)),
        ],
      ),
    );
  }
}

// ── Totales ───────────────────────────────────────────────────────────────

class _Totales extends StatelessWidget {
  const _Totales({required this.resumen});

  final ResumenTablero? resumen;

  @override
  Widget build(BuildContext context) {
    final r = resumen;
    final totales = [
      ('Entradas', r?.totalEntradas, Icons.south_west_rounded, ColoresApp.verde),
      ('Salidas', r?.totalSalidas, Icons.north_east_rounded, ColoresApp.azulMarino),
      ('Colegios', r?.totalColegios, Icons.school_outlined, ColoresApp.azulMedio),
      ('Uniformes', r?.totalUniformes, Icons.checkroom_outlined, ColoresApp.verde),
      ('Proveedores', r?.totalProveedores, Icons.storefront_outlined, ColoresApp.stockBajoTexto),
      ('Usuarios', r?.totalUsuarios, Icons.group_outlined, ColoresApp.textoSecundario),
    ];
    return LayoutBuilder(
      builder: (context, limites) {
        final ancho = (limites.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (etiqueta, valor, icono, color) in totales)
              SizedBox(
                width: ancho,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icono, size: 18, color: color),
                        const SizedBox(height: 8),
                        Text(
                          valor == null ? '–' : Formatos.numero(valor),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(etiqueta, style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Asistente ─────────────────────────────────────────────────────────────

class _AccesoAsistente extends StatelessWidget {
  const _AccesoAsistente();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresApp.textoTitulo,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(RutasApp.adminIa),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColoresApp.verdeClaro.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: ColoresApp.verdeClaro),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregúntale al asistente',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Resumen del día, compras sugeridas y análisis con IA',
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
