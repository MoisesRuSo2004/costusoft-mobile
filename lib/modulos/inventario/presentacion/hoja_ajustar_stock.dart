import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/aviso_en_linea.dart';
import '../../../compartido/widgets/campo_con_etiqueta.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../dominio/insumo.dart';
import 'proveedores_inventario.dart';

/// Abre la hoja para corregir el stock tras un conteo físico.
/// Devuelve el insumo actualizado, o `null` si se canceló.
Future<Insumo?> mostrarHojaAjustarStock(BuildContext context, Insumo insumo) => showModalBottomSheet<Insumo>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _HojaAjustarStock(insumo: insumo),
);

class _HojaAjustarStock extends ConsumerStatefulWidget {
  const _HojaAjustarStock({required this.insumo});

  final Insumo insumo;

  @override
  ConsumerState<_HojaAjustarStock> createState() => _EstadoHojaAjustarStock();
}

class _EstadoHojaAjustarStock extends ConsumerState<_HojaAjustarStock> {
  final _llaveFormulario = GlobalKey<FormState>();
  late final _controladorStock = TextEditingController(text: '${widget.insumo.stock}');
  final _controladorObservacion = TextEditingController();
  bool _guardando = false;
  String? _error;

  int? get _nuevoStock => int.tryParse(_controladorStock.text);

  @override
  void dispose() {
    _controladorStock.dispose();
    _controladorObservacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_llaveFormulario.currentState?.validate() ?? false)) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final resultado = await ref
        .read(proveedorRepositorioInventario)
        .ajustarStock(insumoId: widget.insumo.id, nuevoStock: _nuevoStock!, observacion: _controladorObservacion.text);
    if (!mounted) return;
    switch (resultado) {
      case Exito(:final datos):
        ref.read(proveedorInsumos.notifier).reemplazar(datos);
        Navigator.pop(context, datos);
      case Falla(:final fallo):
        setState(() {
          _guardando = false;
          _error = fallo.mensaje;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final insumo = widget.insumo;
    final textos = Theme.of(context).textTheme;
    final nuevo = _nuevoStock;
    final diferencia = nuevo == null ? null : nuevo - insumo.stock;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _llaveFormulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ajustar stock', style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${insumo.nombre} · stock actual ${Formatos.numero(insumo.stock)} ${insumo.unidadMedida} '
              '(mínimo ${Formatos.numero(insumo.stockMinimo)})',
              style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: 20),
            if (_error != null) AvisoEnLinea.error(_error!),
            CampoConEtiqueta(
              etiqueta: 'Nuevo stock (${insumo.unidadMedida})',
              obligatorio: true,
              campo: TextFormField(
                controller: _controladorStock,
                enabled: !_guardando,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cantidad contada',
                  helperText: diferencia == null || diferencia == 0
                      ? 'Escribe la cantidad real tras el conteo físico.'
                      : '${diferencia > 0 ? 'Aumenta' : 'Disminuye'} ${Formatos.numero(diferencia.abs())} '
                            '${insumo.unidadMedida}',
                ),
                validator: (valor) {
                  final numero = int.tryParse(valor ?? '');
                  if (numero == null) return 'Escribe una cantidad';
                  if (numero < 0) return 'El stock no puede ser negativo';
                  if (numero == insumo.stock) return 'Es igual al stock actual';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            CampoConEtiqueta(
              etiqueta: 'Observación',
              campo: TextFormField(
                controller: _controladorObservacion,
                enabled: !_guardando,
                maxLength: 255,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Ej.: conteo físico del 8 de octubre'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Guardar ajuste'),
            ),
          ],
        ),
      ),
    );
  }
}
