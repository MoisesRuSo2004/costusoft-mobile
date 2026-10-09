import 'package:flutter/material.dart';

import '../../nucleo/tema/colores_app.dart';

/// Recuadro de aviso dentro de un formulario: error del servidor, o un
/// mensaje informativo (p. ej. "Tu sesión expiró").
class AvisoEnLinea extends StatelessWidget {
  const AvisoEnLinea.error(this.mensaje, {super.key})
    : _fondo = ColoresApp.errorFondo,
      _borde = ColoresApp.errorBorde,
      _color = ColoresApp.error,
      _icono = Icons.error_outline_rounded;

  const AvisoEnLinea.informacion(this.mensaje, {super.key})
    : _fondo = ColoresApp.infoFondo,
      _borde = ColoresApp.infoBorde,
      _color = ColoresApp.azulMarino,
      _icono = Icons.info_outline_rounded;

  const AvisoEnLinea.exito(this.mensaje, {super.key})
    : _fondo = ColoresApp.exitoFondo,
      _borde = const Color(0xFFBBF7D0),
      _color = const Color(0xFF166534),
      _icono = Icons.check_circle_outline_rounded;

  final String mensaje;
  final Color _fondo;
  final Color _borde;
  final Color _color;
  final IconData _icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icono, color: _color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: _color, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
