import 'package:flutter/material.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../dominio/pedido.dart';

/// Colores de cada estado, los mismos de la plataforma web.
extension EstiloEstadoPedido on EstadoPedido {
  Color get color => switch (this) {
    EstadoPedido.borrador => const Color(0xFF6B7280),
    EstadoPedido.calculado => const Color(0xFF2563EB),
    EstadoPedido.confirmado => const Color(0xFF0891B2),
    EstadoPedido.enProduccion => const Color(0xFFD97706),
    EstadoPedido.listoParaEntrega => const Color(0xFF16A34A),
    EstadoPedido.entregado => const Color(0xFF15803D),
    EstadoPedido.cancelado => const Color(0xFFDC2626),
  };

  Color get fondo => switch (this) {
    EstadoPedido.borrador => const Color(0xFFF9FAFB),
    EstadoPedido.calculado => const Color(0xFFEFF6FF),
    EstadoPedido.confirmado => const Color(0xFFECFEFF),
    EstadoPedido.enProduccion => const Color(0xFFFFFBEB),
    EstadoPedido.listoParaEntrega => const Color(0xFFF0FDF4),
    EstadoPedido.entregado => const Color(0xFFDCFCE7),
    EstadoPedido.cancelado => const Color(0xFFFEF2F2),
  };

  IconData get icono => switch (this) {
    EstadoPedido.borrador => Icons.edit_note_rounded,
    EstadoPedido.calculado => Icons.calculate_outlined,
    EstadoPedido.confirmado => Icons.task_alt_rounded,
    EstadoPedido.enProduccion => Icons.precision_manufacturing_outlined,
    EstadoPedido.listoParaEntrega => Icons.inventory_rounded,
    EstadoPedido.entregado => Icons.verified_rounded,
    EstadoPedido.cancelado => Icons.cancel_outlined,
  };

  Widget get insignia => Insignia(texto: etiqueta, fondo: fondo, color: color, punto: color);
}
