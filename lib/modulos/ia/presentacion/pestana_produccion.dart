import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../datos/modelos_ia.dart';
import '../dominio/entidades_ia.dart';
import 'proveedores_ia.dart';

/// Plan de producción óptimo (programación lineal entera con PuLP/CBC):
/// cuántas prendas fabricar para maximizar la utilidad con el stock actual.
class PestanaProduccion extends ConsumerStatefulWidget {
  const PestanaProduccion({super.key});

  @override
  ConsumerState<PestanaProduccion> createState() => _EstadoPestanaProduccion();
}

class _EstadoPestanaProduccion extends ConsumerState<PestanaProduccion> with AutomaticKeepAliveClientMixin {
  int? _colegioId;
  bool _incluirDemanda = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colegios = ref.watch(proveedorColegios);
    final plan = ref.watch(proveedorPlanCalculado);
    final historial = ref.watch(proveedorHistorialOptimizacion);
    final calculando = plan is AsyncLoading;

    return RefreshIndicator(
      color: ColoresApp.verde,
      onRefresh: () async => ref.invalidate(proveedorHistorialOptimizacion),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Plan de producción óptimo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Calcula cuántas prendas fabricar para obtener la mayor utilidad posible con el '
                    'inventario actual (programación lineal entera).',
                    style: TextStyle(fontSize: 13, color: ColoresApp.textoSecundario, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  switch (colegios) {
                    AsyncValue(:final value?) => DropdownButtonFormField<int>(
                      initialValue: _colegioId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Colegio'),
                      items: [
                        for (final c in value)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: calculando ? null : (id) => setState(() => _colegioId = id),
                    ),
                    AsyncError(:final error) => Text(
                      mensajeDeError(error),
                      style: const TextStyle(color: ColoresApp.error),
                    ),
                    _ => const BloqueEsqueleto(alto: 52, radio: 12),
                  },
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _incluirDemanda,
                    onChanged: calculando ? null : (v) => setState(() => _incluirDemanda = v),
                    activeThumbColor: ColoresApp.verde,
                    title: const Text('Considerar pedidos activos', style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      'Limita la producción a lo que piden los pedidos en curso',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _colegioId == null || calculando
                        ? null
                        : () => ref
                              .read(proveedorPlanCalculado.notifier)
                              .calcular(colegioId: _colegioId!, incluirDemanda: _incluirDemanda),
                    icon: calculando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.calculate_outlined),
                    label: Text(calculando ? 'Resolviendo…' : 'Calcular plan óptimo'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cada cálculo queda guardado en el historial.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue),
                  ),
                ],
              ),
            ),
          ),
          if (plan case AsyncData(:final value)) ...[const SizedBox(height: 16), _ResultadoPlan(plan: value)],
          if (plan case AsyncError(:final error)) ...[
            const SizedBox(height: 16),
            EstadoError(
              mensaje: mensajeDeError(error),
              alReintentar: () => ref
                  .read(proveedorPlanCalculado.notifier)
                  .calcular(colegioId: _colegioId!, incluirDemanda: _incluirDemanda),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Historial de cálculos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
          ),
          const SizedBox(height: 10),
          switch (historial) {
            AsyncValue(:final value?) when value.isEmpty => const EstadoVacio(
              titulo: 'Sin cálculos todavía',
              mensaje: 'Calcula el primer plan óptimo para un colegio.',
              icono: Icons.history_rounded,
            ),
            AsyncValue(:final value?) => Column(children: [for (final p in value) _FilaHistorial(plan: p)]),
            AsyncError(:final error) => EstadoError(
              mensaje: mensajeDeError(error),
              alReintentar: () => ref.invalidate(proveedorHistorialOptimizacion),
            ),
            _ => const Column(
              children: [
                BloqueEsqueleto(alto: 72, radio: 12),
                SizedBox(height: 10),
                BloqueEsqueleto(alto: 72, radio: 12),
              ],
            ),
          },
        ],
      ),
    );
  }
}

/// Resultado completo de un cálculo: utilidad, prendas y uso de insumos.
class _ResultadoPlan extends StatelessWidget {
  const _ResultadoPlan({required this.plan});

  final PlanProduccion plan;

  @override
  Widget build(BuildContext context) {
    final prendas = plan.unidadesPorPrenda.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maximo = prendas.isEmpty ? 1 : prendas.first.value.clamp(1, 1 << 30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Insignia(
                  texto: plan.esOptimo ? 'Solución óptima' : 'Sin solución',
                  fondo: plan.esOptimo ? ColoresApp.disponibleFondo : ColoresApp.sinStockFondo,
                  color: plan.esOptimo ? ColoresApp.disponibleTexto : ColoresApp.sinStockTexto,
                  punto: plan.esOptimo ? ColoresApp.disponiblePunto : ColoresApp.sinStockPunto,
                ),
                const Spacer(),
                if (plan.nombreColegio != null)
                  Flexible(
                    child: Text(
                      plan.nombreColegio!,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Indicador(titulo: 'Utilidad máxima', valor: Formatos.moneda(plan.utilidadTotal)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Indicador(titulo: 'Total de prendas', valor: Formatos.numero(plan.totalPrendas)),
                ),
              ],
            ),
            if (prendas.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Prendas a producir', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              for (final p in prendas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nombrePrenda(p.key),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: p.value == 0 ? ColoresApp.textoTenue : ColoresApp.textoTitulo,
                              ),
                            ),
                          ),
                          Text(
                            p.value == 0 ? 'No producir' : '${Formatos.numero(p.value)} und.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: p.value == 0 ? ColoresApp.textoTenue : ColoresApp.verde,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: p.value / maximo,
                          minHeight: 6,
                          backgroundColor: ColoresApp.fondoSuave,
                          color: ColoresApp.verde,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (plan.usoInsumos.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Uso de insumos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              const Text(
                'Los insumos al 100 % son los que impiden producir más.',
                style: TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
              ),
              const SizedBox(height: 10),
              for (final uso in plan.usoInsumos) _FilaUsoInsumo(uso: uso),
            ],
            if (plan.mensaje.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.mensaje, style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ColoresApp.fondoSuave, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FilaUsoInsumo extends StatelessWidget {
  const _FilaUsoInsumo({required this.uso});

  final UsoInsumo uso;

  @override
  Widget build(BuildContext context) {
    final color = uso.esLimitante
        ? ColoresApp.riesgoAlto
        : (uso.utilizacion >= 75 ? ColoresApp.riesgoMedio : ColoresApp.azulMarino);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(uso.nombre, style: const TextStyle(fontSize: 13.5))),
              if (uso.esLimitante)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Insignia(texto: 'Limitante', fondo: ColoresApp.sinStockFondo, color: ColoresApp.sinStockTexto),
                ),
              Text(
                '${Formatos.numero(uso.utilizacion)} %',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (uso.utilizacion / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: ColoresApp.fondoSuave,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Usa ${Formatos.numero(uso.usado)} de ${Formatos.numero(uso.disponible)} ${uso.unidad}',
            style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue),
          ),
        ],
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({required this.plan});

  final PlanProduccion plan;

  void _verDetalle(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, desplazamiento) => ListView(
        controller: desplazamiento,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (plan.fecha != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Calculado ${Formatos.haceCuanto(plan.fecha!)}',
                style: const TextStyle(color: ColoresApp.textoSecundario),
              ),
            ),
          _ResultadoPlan(plan: plan),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _verDetalle(context),
          leading: CircleAvatar(
            backgroundColor: plan.esOptimo ? ColoresApp.disponibleFondo : ColoresApp.sinStockFondo,
            child: Icon(
              plan.esOptimo ? Icons.check_rounded : Icons.close_rounded,
              color: plan.esOptimo ? ColoresApp.disponibleTexto : ColoresApp.sinStockTexto,
            ),
          ),
          title: Text(
            plan.nombreColegio ?? 'Colegio',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${Formatos.moneda(plan.utilidadTotal)} · ${Formatos.numero(plan.totalPrendas)} prendas'
            '${plan.fecha != null ? ' · ${Formatos.fecha(plan.fecha!)}' : ''}',
            style: const TextStyle(fontSize: 12.5),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
