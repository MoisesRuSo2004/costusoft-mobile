import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../compartido/widgets/aviso_despertando_motor.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/red/despertar_motor.dart';
import '../../../nucleo/rutas/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../inventario/dominio/prediccion_insumo.dart';
import '../../inventario/presentacion/estilos_inventario.dart';
import '../../inventario/presentacion/proveedores_inventario.dart';
import 'proveedores_ia.dart';

/// Riesgo de desabastecimiento de todo el inventario (Prophet + XGBoost).
class PestanaRiesgo extends ConsumerWidget {
  const PestanaRiesgo({super.key});

  static const _niveles = [NivelRiesgo.critico, NivelRiesgo.alto, NivelRiesgo.medio, NivelRiesgo.bajo];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predicciones = ref.watch(proveedorPredicciones);
    final segundosDespertando = ref.watch(proveedorDespertarMotor);

    Future<void> actualizar() async {
      ref.invalidate(proveedorPredicciones);
      try {
        await ref.read(proveedorPredicciones.future);
      } on Object {
        // El error se muestra en pantalla.
      }
    }

    return RefreshIndicator(
      color: ColoresApp.verde,
      onRefresh: actualizar,
      child: switch (predicciones) {
        AsyncValue(:final value?) => _Contenido(predicciones: value),
        AsyncError(:final error) => ListView(
          children: [EstadoError(mensaje: mensajeDeError(error), alReintentar: actualizar)],
        ),
        _ when segundosDespertando != null => ListView(
          padding: const EdgeInsets.all(20),
          children: [AvisoDespertandoMotor(segundos: segundosDespertando)],
        ),
        _ => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            BloqueEsqueleto(alto: 200, radio: 16),
            SizedBox(height: 16),
            BloqueEsqueleto(alto: 90, radio: 14),
            SizedBox(height: 10),
            BloqueEsqueleto(alto: 90, radio: 14),
          ],
        ),
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.predicciones});

  final List<PrediccionInsumo> predicciones;

  @override
  Widget build(BuildContext context) {
    final porNivel = {
      for (final nivel in PestanaRiesgo._niveles) nivel: predicciones.where((p) => p.nivelRiesgo == nivel).toList(),
    };
    final enRiesgo = (porNivel[NivelRiesgo.critico]!.length) + (porNivel[NivelRiesgo.alto]!.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _TarjetaDistribucion(porNivel: porNivel, total: predicciones.length, enRiesgo: enRiesgo),
        const SizedBox(height: 20),
        for (final nivel in [NivelRiesgo.critico, NivelRiesgo.alto, NivelRiesgo.medio])
          if (porNivel[nivel]!.isNotEmpty) ...[
            _TituloNivel(nivel: nivel, cantidad: porNivel[nivel]!.length),
            for (final p in porNivel[nivel]!) _TarjetaPrediccion(prediccion: p),
            const SizedBox(height: 12),
          ],
        if (porNivel[NivelRiesgo.bajo]!.isNotEmpty)
          Card(
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(Icons.verified_rounded, color: NivelRiesgo.bajo.color),
                title: Text(
                  'Riesgo bajo · ${porNivel[NivelRiesgo.bajo]!.length} insumos',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: const Text('Con stock suficiente por ahora', style: TextStyle(fontSize: 12.5)),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [for (final p in porNivel[NivelRiesgo.bajo]!) _FilaCompacta(prediccion: p)],
              ),
            ),
          ),
      ],
    );
  }
}

class _TarjetaDistribucion extends StatelessWidget {
  const _TarjetaDistribucion({required this.porNivel, required this.total, required this.enRiesgo});

  final Map<NivelRiesgo, List<PrediccionInsumo>> porNivel;
  final int total;
  final int enRiesgo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riesgo de desabastecimiento',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
            ),
            const SizedBox(height: 2),
            const Text(
              'Clasificación de los modelos de IA por insumo',
              style: TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 42,
                          startDegreeOffset: -90,
                          sections: [
                            for (final nivel in PestanaRiesgo._niveles)
                              if (porNivel[nivel]!.isNotEmpty)
                                PieChartSectionData(
                                  value: porNivel[nivel]!.length.toDouble(),
                                  color: nivel.color,
                                  radius: 20,
                                  showTitle: false,
                                ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$enRiesgo',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1),
                          ),
                          const Text('en riesgo', style: TextStyle(fontSize: 11, color: ColoresApp.textoSecundario)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final nivel in PestanaRiesgo._niveles)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: nivel.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(nivel.etiqueta, style: const TextStyle(fontSize: 13.5))),
                              Text(
                                '${porNivel[nivel]!.length}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Total', style: TextStyle(fontSize: 13, color: ColoresApp.textoSecundario)),
                          ),
                          Text('$total', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloNivel extends StatelessWidget {
  const _TituloNivel({required this.nivel, required this.cantidad});

  final NivelRiesgo nivel;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: nivel.color),
          const SizedBox(width: 8),
          Text(
            'Riesgo ${nivel.etiqueta.toLowerCase()} · $cantidad',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: nivel.color),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPrediccion extends StatelessWidget {
  const _TarjetaPrediccion({required this.prediccion});

  final PrediccionInsumo prediccion;

  @override
  Widget build(BuildContext context) {
    final p = prediccion;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.nivelRiesgo.color.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          onTap: () => context.go(RutasApp.adminDetalleInsumo(p.insumoId)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColoresApp.textoTitulo,
                        ),
                      ),
                    ),
                    Text(
                      '${Formatos.numero(p.stockActual)} / ${Formatos.numero(p.stockMinimo)} ${p.unidadMedida}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.nivelRiesgo.color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.mensaje, style: const TextStyle(fontSize: 13.5, color: ColoresApp.textoEtiqueta, height: 1.4)),
                if (p.recomendacion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 16, color: ColoresApp.stockBajoTexto),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.recomendacion,
                          style: const TextStyle(fontSize: 13, color: ColoresApp.stockBajoTexto, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ],
                if (p.fechaAlerta != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Alerta estimada: ${Formatos.fecha(p.fechaAlerta!)}',
                    style: const TextStyle(fontSize: 12, color: ColoresApp.textoTenue),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaCompacta extends StatelessWidget {
  const _FilaCompacta({required this.prediccion});

  final PrediccionInsumo prediccion;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(RutasApp.adminDetalleInsumo(prediccion.insumoId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(prediccion.nombre, style: const TextStyle(fontSize: 13.5))),
            Text(
              '${Formatos.numero(prediccion.stockActual)} ${prediccion.unidadMedida}',
              style: const TextStyle(fontSize: 13, color: ColoresApp.textoSecundario),
            ),
            const Icon(Icons.chevron_right_rounded, color: ColoresApp.textoTenue),
          ],
        ),
      ),
    );
  }
}
