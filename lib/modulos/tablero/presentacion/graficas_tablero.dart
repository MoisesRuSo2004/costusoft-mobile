import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../nucleo/tema/colores_app.dart';
import '../dominio/resumen_tablero.dart';

/// Entradas y salidas por mes (barras agrupadas), últimos 6 meses.
class GraficaMovimientosMensuales extends StatelessWidget {
  const GraficaMovimientosMensuales({super.key, required this.meses});

  final List<MovimientosDelMes> meses;

  @override
  Widget build(BuildContext context) {
    final visibles = meses.length > 6 ? meses.sublist(meses.length - 6) : meses;
    if (visibles.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('Sin movimientos registrados', style: TextStyle(color: ColoresApp.textoSecundario)),
        ),
      );
    }
    final maximo = visibles.map((m) => math.max(m.entradas, m.salidas)).reduce(math.max);
    final tope = maximo == 0 ? 4.0 : (maximo * 1.25).ceilToDouble();
    final formatoMes = DateFormat('MMM', 'es_CO');

    return SizedBox(
      height: 190,
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: tope / 4,
                getTitlesWidget: (valor, meta) => valor == meta.max
                    ? const SizedBox.shrink()
                    : Text('${valor.round()}', style: const TextStyle(fontSize: 11, color: ColoresApp.textoTenue)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (valor, _) {
                  final mes = formatoMes.format(visibles[valor.toInt()].mes).replaceAll('.', '');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      mes[0].toUpperCase() + mes.substring(1),
                      style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoSecundario),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => ColoresApp.textoTitulo,
              getTooltipItem: (grupo, _, barra, indiceBarra) => BarTooltipItem(
                '${indiceBarra == 0 ? 'Entradas' : 'Salidas'}: ${barra.toY.round()}',
                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < visibles.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: visibles[i].entradas.toDouble(),
                    width: 10,
                    color: ColoresApp.verde,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: visibles[i].salidas.toDouble(),
                    width: 10,
                    color: ColoresApp.azulMarino,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
