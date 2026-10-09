import 'package:flutter/material.dart';

import '../../ia/presentacion/pestana_asistente.dart';

/// Asistente IA del colegio: responde con los datos de los pedidos de su
/// institución (`POST /api/institucion/ia/chat`).
class PaginaAsistenteInstitucional extends StatelessWidget {
  const PaginaAsistenteInstitucional({super.key});

  /// Las mismas sugerencias del portal web.
  static const _sugerencias = [
    '¿En qué estado está mi último pedido?',
    '¿Cuándo llegará mi pedido activo?',
    '¿Hay algún pedido listo para entrega?',
    '¿Cuántos uniformes tiene configurados mi colegio?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente IA')),
      body: const PestanaAsistente(sugerencias: _sugerencias, ejemplo: '¿Cuándo llegará mi pedido activo?'),
    );
  }
}
