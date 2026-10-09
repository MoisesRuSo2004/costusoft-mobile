import 'package:flutter/material.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';

/// Colores del estado del stock (mismos de `InventarioClient.tsx`).
extension EstiloEstadoStock on EstadoStock {
  Color get fondo => switch (this) {
    EstadoStock.disponible => ColoresApp.disponibleFondo,
    EstadoStock.stockBajo => ColoresApp.stockBajoFondo,
    EstadoStock.sinStock => ColoresApp.sinStockFondo,
  };

  Color get colorTexto => switch (this) {
    EstadoStock.disponible => ColoresApp.disponibleTexto,
    EstadoStock.stockBajo => ColoresApp.stockBajoTexto,
    EstadoStock.sinStock => ColoresApp.sinStockTexto,
  };

  Color get colorPunto => switch (this) {
    EstadoStock.disponible => ColoresApp.disponiblePunto,
    EstadoStock.stockBajo => ColoresApp.stockBajoPunto,
    EstadoStock.sinStock => ColoresApp.sinStockPunto,
  };

  Widget get insignia => Insignia(texto: etiqueta, fondo: fondo, color: colorTexto, punto: colorPunto);
}

/// Colores del nivel de riesgo de XGBoost.
extension EstiloNivelRiesgo on NivelRiesgo {
  Color get color => switch (this) {
    NivelRiesgo.bajo => ColoresApp.riesgoBajo,
    NivelRiesgo.medio => ColoresApp.riesgoMedio,
    NivelRiesgo.alto => ColoresApp.riesgoAlto,
    NivelRiesgo.critico => ColoresApp.riesgoCritico,
    NivelRiesgo.desconocido => ColoresApp.riesgoDesconocido,
  };

  Color get fondo => color.withValues(alpha: 0.1);
}

/// Icono representativo de cada tipo de insumo.
IconData iconoDeTipo(String tipo) => switch (tipo.toLowerCase()) {
  'tela' => Icons.texture_rounded,
  'hilo' => Icons.gesture_rounded,
  'botón' || 'boton' => Icons.radio_button_checked_rounded,
  'cierre' => Icons.vertical_align_center_rounded,
  'accesorio' => Icons.auto_awesome_rounded,
  'herraje' => Icons.hardware_rounded,
  'forro' => Icons.layers_rounded,
  _ => Icons.category_rounded,
};

/// Círculo con el icono del tipo de insumo.
class IconoTipoInsumo extends StatelessWidget {
  const IconoTipoInsumo({super.key, required this.tipo, this.tamano = 44});

  final String tipo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: ColoresApp.infoFondo, borderRadius: BorderRadius.circular(tamano * 0.3)),
      child: Icon(iconoDeTipo(tipo), color: ColoresApp.azulMarino, size: tamano * 0.5),
    );
  }
}
