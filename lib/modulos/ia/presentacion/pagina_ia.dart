import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';
import 'pestana_asistente.dart';
import 'pestana_produccion.dart';
import 'pestana_riesgo.dart';

/// Módulo de inteligencia artificial del administrador:
/// asistente (LLM), riesgo de desabastecimiento (ML) y producción óptima (ILP).
class PaginaIa extends StatelessWidget {
  const PaginaIa({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligencia artificial'),
          bottom: const TabBar(
            labelColor: ColoresApp.verde,
            unselectedLabelColor: ColoresApp.textoSecundario,
            indicatorColor: ColoresApp.verde,
            indicatorWeight: 2.5,
            dividerColor: ColoresApp.borde,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: 'Asistente', icon: Icon(Icons.auto_awesome_outlined, size: 20)),
              Tab(text: 'Riesgo', icon: Icon(Icons.warning_amber_rounded, size: 20)),
              Tab(text: 'Producción', icon: Icon(Icons.precision_manufacturing_outlined, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(children: [PestanaAsistente(), PestanaRiesgo(), PestanaProduccion()]),
      ),
    );
  }
}
