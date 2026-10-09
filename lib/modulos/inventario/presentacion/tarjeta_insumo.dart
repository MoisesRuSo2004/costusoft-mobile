import 'package:flutter/material.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';
import 'estilos_inventario.dart';

/// Tarjeta de un insumo en la lista del inventario.
class TarjetaInsumo extends StatelessWidget {
  const TarjetaInsumo({super.key, required this.insumo, required this.alTocar, this.riesgo, this.mostrarRiesgo = true});

  final Insumo insumo;
  final VoidCallback alTocar;

  /// `null` mientras el riesgo de IA aún se está calculando.
  final NivelRiesgo? riesgo;

  /// `false` para los roles sin acceso a las predicciones (Bodega).
  final bool mostrarRiesgo;

  @override
  Widget build(BuildContext context) {
    final estado = insumo.estado;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconoTipoInsumo(tipo: insumo.tipo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insumo.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ColoresApp.textoTitulo,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${insumo.tipo} · Mín. ${Formatos.numero(insumo.stockMinimo)} ${insumo.unidadMedida}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatos.numero(insumo.stock),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: estado == EstadoStock.disponible ? ColoresApp.textoTitulo : estado.colorTexto,
                        ),
                      ),
                      Text(
                        insumo.unidadMedida,
                        style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoSecundario),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: insumo.nivelRelativo,
                  minHeight: 5,
                  backgroundColor: ColoresApp.fondoSuave,
                  color: estado.colorPunto,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  estado.insignia,
                  const Spacer(),
                  if (mostrarRiesgo) _IndicadorRiesgo(riesgo: riesgo),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nivel de riesgo de IA en la esquina inferior de la tarjeta.
class _IndicadorRiesgo extends StatelessWidget {
  const _IndicadorRiesgo({required this.riesgo});

  final NivelRiesgo? riesgo;

  @override
  Widget build(BuildContext context) {
    final nivel = riesgo;
    if (nivel == null) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6)),
          SizedBox(width: 6),
          Text('Analizando riesgo…', style: TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue)),
        ],
      );
    }
    if (nivel == NivelRiesgo.desconocido) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 14, color: nivel.color),
        const SizedBox(width: 4),
        Text(
          'Riesgo ${nivel.etiqueta.toLowerCase()}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: nivel.color),
        ),
      ],
    );
  }
}

/// Tarjeta gris con la misma forma, mientras carga la lista.
class TarjetaInsumoEsqueleto extends StatelessWidget {
  const TarjetaInsumoEsqueleto({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _caja(44, 44, 13),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_caja(null, 14, 6), const SizedBox(height: 8), _caja(120, 10, 6)],
                  ),
                ),
                const SizedBox(width: 12),
                _caja(36, 22, 6),
              ],
            ),
            const SizedBox(height: 14),
            _caja(null, 5, 99),
          ],
        ),
      ),
    );
  }

  static Widget _caja(double? ancho, double alto, double radio) =>
      BloqueEsqueleto(ancho: ancho, alto: alto, radio: radio);
}
