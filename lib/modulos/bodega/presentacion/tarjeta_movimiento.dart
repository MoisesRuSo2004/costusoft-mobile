import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/aviso_en_linea.dart';
import '../../../compartido/widgets/campo_con_etiqueta.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/sin_conexion/acciones_sin_conexion.dart';
import '../../../nucleo/sin_conexion/sincronizacion.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../autenticacion/dominio/estado_sesion.dart';
import '../../autenticacion/dominio/rol_usuario.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../dominio/movimiento.dart';
import 'proveedores_bodega.dart';

/// Colores e iconos de entradas (verde) y salidas (azul).
extension EstiloTipoMovimiento on TipoMovimiento {
  Color get color => this == TipoMovimiento.entrada ? ColoresApp.verde : ColoresApp.azulMarino;

  IconData get icono => this == TipoMovimiento.entrada ? Icons.south_west_rounded : Icons.north_east_rounded;
}

extension EstiloEstadoMovimiento on EstadoMovimiento {
  Widget get insignia => switch (this) {
    EstadoMovimiento.pendiente => const Insignia(
      texto: 'Pendiente',
      fondo: ColoresApp.stockBajoFondo,
      color: ColoresApp.stockBajoTexto,
      punto: ColoresApp.stockBajoPunto,
    ),
    EstadoMovimiento.confirmada => const Insignia(
      texto: 'Confirmada',
      fondo: ColoresApp.disponibleFondo,
      color: ColoresApp.disponibleTexto,
      punto: ColoresApp.disponiblePunto,
    ),
    EstadoMovimiento.rechazada => const Insignia(
      texto: 'Rechazada',
      fondo: ColoresApp.sinStockFondo,
      color: ColoresApp.sinStockTexto,
      punto: ColoresApp.sinStockPunto,
    ),
  };
}

/// Tarjeta de una entrada o salida. Al tocarla abre el detalle con las acciones.
class TarjetaMovimiento extends ConsumerWidget {
  const TarjetaMovimiento({super.key, required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = movimiento;
    final fecha = m.fecha ?? m.creadoEn;
    final enCola = ref.watch(proveedorSincronizacion.select((e) => e.recursosEnCola.contains(recursoDeMovimiento(m))));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => mostrarDetalleMovimiento(context, m),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: m.tipo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(m.tipo.icono, color: m.tipo.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${m.tipo.etiqueta} #${m.id}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        const Spacer(),
                        if (enCola) const InsigniaPorEnviar() else m.estado.insignia,
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.descripcion ?? m.tercero ?? 'Sin descripción',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: ColoresApp.textoEtiqueta),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        '${m.detalles.length} ${m.detalles.length == 1 ? 'insumo' : 'insumos'}',
                        if (m.tercero != null && m.descripcion != null) m.tercero!,
                        if (fecha != null) Formatos.fecha(fecha),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior con el detalle del movimiento y, si está pendiente y el rol
/// lo permite (Administrador o Bodega), los botones para confirmar o rechazar.
Future<void> mostrarDetalleMovimiento(BuildContext context, Movimiento movimiento) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    maxChildSize: 0.95,
    builder: (_, desplazamiento) => _DetalleMovimiento(movimiento: movimiento, desplazamiento: desplazamiento),
  ),
);

class _DetalleMovimiento extends ConsumerStatefulWidget {
  const _DetalleMovimiento({required this.movimiento, required this.desplazamiento});

  final Movimiento movimiento;
  final ScrollController desplazamiento;

  @override
  ConsumerState<_DetalleMovimiento> createState() => _EstadoDetalleMovimiento();
}

class _EstadoDetalleMovimiento extends ConsumerState<_DetalleMovimiento> {
  bool _procesando = false;
  bool _rechazando = false;
  String? _error;
  final _controladorMotivo = TextEditingController();

  @override
  void dispose() {
    _controladorMotivo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() => _verificar();

  Future<void> _rechazar() async {
    final motivo = _controladorMotivo.text.trim();
    if (motivo.length < 5) {
      setState(() => _error = 'Escribe el motivo del rechazo (mínimo 5 caracteres).');
      return;
    }
    await _verificar(motivoRechazo: motivo);
  }

  Future<void> _verificar({String? motivoRechazo}) async {
    final m = widget.movimiento;
    setState(() {
      _procesando = true;
      _error = null;
    });
    final resultado = await verificarMovimiento(ref, m, motivoRechazo: motivoRechazo);
    if (!mounted) return;
    final nombre = '${m.tipo.etiqueta} #${m.id}';
    final String aviso;
    switch (resultado) {
      case AccionFallida(:final fallo):
        setState(() {
          _procesando = false;
          _error = fallo.mensaje;
        });
        return;
      case AccionEnCola():
        aviso =
            'Sin conexión: ${motivoRechazo == null ? 'la confirmación' : 'el rechazo'} de $nombre '
            'quedó en cola y se enviará al recuperar la red.';
      case AccionAplicada():
        aviso = motivoRechazo != null
            ? '$nombre rechazada. El stock no cambió.'
            : '$nombre confirmada: stock ${m.tipo == TipoMovimiento.entrada ? 'aumentado' : 'descontado'}.';
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movimiento;
    final sesion = ref.watch(proveedorSesion);
    final rol = sesion is SesionActiva ? sesion.usuario.rol : null;
    final enCola = ref.watch(proveedorSincronizacion.select((e) => e.recursosEnCola.contains(recursoDeMovimiento(m))));
    final puedeVerificar =
        !enCola &&
        m.estado == EstadoMovimiento.pendiente &&
        (rol == RolUsuario.administrador || rol == RolUsuario.bodega);

    return ListView(
      controller: widget.desplazamiento,
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      children: [
        Row(
          children: [
            Icon(m.tipo.icono, color: m.tipo.color),
            const SizedBox(width: 8),
            Text('${m.tipo.etiqueta} #${m.id}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const Spacer(),
            m.estado.insignia,
          ],
        ),
        const SizedBox(height: 14),
        for (final (titulo, valor) in [
          if (m.descripcion != null) ('Descripción', m.descripcion!),
          if (m.tercero != null) (m.tipo == TipoMovimiento.entrada ? 'Proveedor' : 'Colegio', m.tercero!),
          if (m.fecha != null) ('Fecha', Formatos.fecha(m.fecha!)),
          if (m.confirmadaPor != null)
            (
              m.estado == EstadoMovimiento.rechazada ? 'Rechazada por' : 'Confirmada por',
              '${m.confirmadaPor}${m.confirmadaEn != null ? ' · ${Formatos.haceCuanto(m.confirmadaEn!)}' : ''}',
            ),
          if (m.motivoRechazo != null) ('Motivo del rechazo', m.motivoRechazo!),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(titulo, style: const TextStyle(color: ColoresApp.textoSecundario, fontSize: 13)),
                ),
                Expanded(child: Text(valor, style: const TextStyle(fontSize: 13.5))),
              ],
            ),
          ),
        const SizedBox(height: 10),
        const Text('Insumos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < m.detalles.length; i++) ...[
                ListTile(
                  dense: true,
                  title: Text(m.detalles[i].nombreInsumo, style: const TextStyle(fontSize: 14)),
                  trailing: Text(
                    '${m.tipo == TipoMovimiento.entrada ? '+' : '−'}${Formatos.numero(m.detalles[i].cantidad)} '
                    '${m.detalles[i].unidad}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: m.tipo.color, fontSize: 14),
                  ),
                ),
                if (i < m.detalles.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        if (enCola) ...[
          const SizedBox(height: 18),
          const AvisoEnLinea.informacion(
            'Ya verificaste este movimiento sin conexión: está en la bandeja de salida y se enviará al recuperar la red.',
          ),
        ],
        if (puedeVerificar) ...[
          const SizedBox(height: 18),
          if (_error != null) AvisoEnLinea.error(_error!),
          if (_rechazando) ...[
            CampoConEtiqueta(
              etiqueta: 'Motivo del rechazo',
              obligatorio: true,
              campo: TextField(
                controller: _controladorMotivo,
                enabled: !_procesando,
                autofocus: true,
                maxLines: 2,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Ej.: la cantidad recibida no coincide'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: _procesando ? null : () => setState(() => _rechazando = false),
                  child: const Text('Volver'),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ColoresApp.error),
                  onPressed: _procesando ? null : _rechazar,
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ] else ...[
            AvisoEnLinea.informacion(
              m.tipo == TipoMovimiento.entrada
                  ? 'Verifica que lo recibido coincida antes de confirmar: el stock aumentará.'
                  : 'Verifica que lo despachado coincida antes de confirmar: el stock se descontará.',
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _procesando ? null : () => setState(() => _rechazando = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.error,
                      side: const BorderSide(color: ColoresApp.errorBorde, width: 1.5),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _procesando ? null : _confirmar,
                    icon: _procesando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                        : const Icon(Icons.check_rounded),
                    label: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
