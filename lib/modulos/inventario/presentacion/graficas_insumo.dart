import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';

const _estiloEje = TextStyle(fontSize: 11, color: ColoresApp.textoSecundario);

/// Consumo promedio por día en tres ventanas (7, 30 y 90 días): permite ver
/// si el consumo reciente está por encima o por debajo de lo habitual.
class GraficaConsumo extends StatelessWidget {
  const GraficaConsumo({super.key, required this.prediccion, required this.unidad});

  final PrediccionInsumo prediccion;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final promedios = [
      ('7 días', prediccion.consumo7Dias / 7),
      ('30 días', prediccion.consumo30Dias / 30),
      ('90 días', prediccion.consumo90Dias / 90),
    ];
    final maximo = promedios.map((p) => p.$2.toDouble()).reduce(math.max);
    final tope = maximo <= 0 ? 1.0 : maximo * 1.25;

    return SizedBox(
      height: 170,
      child: BarChart(
        BarChartData(
          maxY: tope,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: tope / 4,
            getDrawingHorizontalLine: (_) => const FlLine(color: ColoresApp.borde, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (valor, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(promedios[valor.toInt()].$1, style: _estiloEje),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => ColoresApp.textoTitulo,
              getTooltipItem: (grupo, _, barra, _) => BarTooltipItem(
                '${Formatos.numero(double.parse(barra.toY.toStringAsFixed(2)))} $unidad/día',
                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < promedios.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: promedios[i].$2.toDouble(),
                    width: 34,
                    color: i == 0 ? ColoresApp.verde : ColoresApp.azulMarino.withValues(alpha: 0.75 - i * 0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Proyección del stock con el consumo diario de Prophet: muestra cuándo
/// cruza el stock mínimo y cuándo llegaría a cero.
class GraficaProyeccion extends StatelessWidget {
  const GraficaProyeccion({super.key, required this.insumo, required this.prediccion});

  final Insumo insumo;
  final PrediccionInsumo prediccion;

  @override
  Widget build(BuildContext context) {
    final consumo = prediccion.consumoDiario;
    final diasHastaCero = consumo > 0 ? (insumo.stock / consumo).ceil() : 30;
    final horizonte = math.max(7, math.min(diasHastaCero + 3, 90));
    final puntos = [
      for (var dia = 0; dia <= horizonte; dia++) FlSpot(dia.toDouble(), math.max(0, insumo.stock - consumo * dia)),
    ];
    final tope = math.max(insumo.stock, insumo.stockMinimo) * 1.15 + 1;
    final hoy = DateTime.now();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: horizonte.toDouble(),
          minY: 0,
          maxY: tope.toDouble(),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: tope / 4,
            getDrawingHorizontalLine: (_) => const FlLine(color: ColoresApp.borde, strokeWidth: 1),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: insumo.stockMinimo.toDouble(),
                color: ColoresApp.stockBajoPunto,
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(fontSize: 11, color: ColoresApp.stockBajoTexto, fontWeight: FontWeight.w600),
                  labelResolver: (_) => 'Mínimo',
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: tope / 4,
                getTitlesWidget: (valor, meta) => valor == meta.max
                    ? const SizedBox.shrink()
                    : Text(Formatos.numero(valor.round()), style: _estiloEje),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: math.max(1, (horizonte / 4).roundToDouble()),
                getTitlesWidget: (valor, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    valor == 0 ? 'Hoy' : Formatos.fecha(hoy.add(Duration(days: valor.toInt()))),
                    style: _estiloEje,
                  ),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => ColoresApp.textoTitulo,
              getTooltipItems: (puntosTocados) => [
                for (final punto in puntosTocados)
                  LineTooltipItem(
                    '${Formatos.fecha(hoy.add(Duration(days: punto.x.toInt())))}\n'
                    '${Formatos.numero(punto.y.round())} ${insumo.unidadMedida}',
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: puntos,
              color: ColoresApp.azulMarino,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ColoresApp.azulMarino.withValues(alpha: 0.18), ColoresApp.azulMarino.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
