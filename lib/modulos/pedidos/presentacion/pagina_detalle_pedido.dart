import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/aviso_en_linea.dart';
import '../../../compartido/widgets/campo_con_etiqueta.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/sin_conexion/acciones_sin_conexion.dart';
import '../../../nucleo/sin_conexion/sincronizacion.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../autenticacion/dominio/estado_sesion.dart';
import '../../autenticacion/dominio/rol_usuario.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../dominio/pedido.dart';
import 'estilos_pedidos.dart';
import 'proveedores_pedidos.dart';

/// Detalle de un pedido con su avance, prendas, cálculo de insumos,
/// historial y la acción para pasar al siguiente estado.
class PaginaDetallePedido extends ConsumerWidget {
  const PaginaDetallePedido({super.key, required this.pedidoId});

  final int pedidoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedido = ref.watch(proveedorPedido(pedidoId));
    final sesion = ref.watch(proveedorSesion);
    final rol = sesion is SesionActiva ? sesion.usuario.rol : RolUsuario.usuario;

    Future<void> actualizar() async {
      ref
        ..invalidate(proveedorPedido(pedidoId))
        ..invalidate(proveedorHistorialPedido(pedidoId));
      try {
        await ref.read(proveedorPedido(pedidoId).future);
      } on Object {
        // Se muestra en pantalla.
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(pedido.value?.numero ?? 'Pedido')),
      body: switch (pedido) {
        AsyncValue(:final value?) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: ColoresApp.verde,
                onRefresh: actualizar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _Encabezado(pedido: value),
                    const SizedBox(height: 14),
                    _Progreso(estado: value.estado),
                    const SizedBox(height: 14),
                    _Informacion(pedido: value),
                    const SizedBox(height: 14),
                    _Prendas(pedido: value),
                    if (value.porcentajeCumplimiento != null || value.insumosNecesarios.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _CalculoInsumos(pedido: value),
                    ],
                    const SizedBox(height: 14),
                    _Historial(pedidoId: pedidoId),
                  ],
                ),
              ),
            ),
            _BarraAcciones(pedido: value, rol: rol),
          ],
        ),
        AsyncError(:final error) => EstadoError(
          mensaje: error is Fallo ? error.mensaje : 'No se pudo cargar el pedido.',
          alReintentar: actualizar,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

// ── Secciones ─────────────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono, required this.child, this.accion});

  final String titulo;
  final IconData icono;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: ColoresApp.azulMarino),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              ?accion,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final estado = pedido.estado;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estado.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: estado.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: estado.color, borderRadius: BorderRadius.circular(12)),
            child: Icon(estado.icono, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estado.etiqueta,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: estado.color),
                ),
                const SizedBox(height: 2),
                Text(pedido.colegio.nombre, style: const TextStyle(fontSize: 13.5, color: ColoresApp.textoEtiqueta)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea de avance: Borrador → … → Entregado.
class _Progreso extends StatelessWidget {
  const _Progreso({required this.estado});

  final EstadoPedido estado;

  static const _cortas = {
    EstadoPedido.borrador: 'Borrador',
    EstadoPedido.calculado: 'Calculado',
    EstadoPedido.confirmado: 'Confirmado',
    EstadoPedido.enProduccion: 'Producción',
    EstadoPedido.listoParaEntrega: 'Listo',
    EstadoPedido.entregado: 'Entregado',
  };

  @override
  Widget build(BuildContext context) {
    if (estado == EstadoPedido.cancelado) {
      return const AvisoEnLinea.error('Este pedido fue cancelado. El historial muestra el motivo.');
    }
    final indiceActual = EstadoPedido.flujo.indexOf(estado);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < EstadoPedido.flujo.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == 0
                                ? Colors.transparent
                                : (i <= indiceActual ? ColoresApp.verde : ColoresApp.borde),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < indiceActual
                                ? ColoresApp.verde
                                : (i == indiceActual ? EstadoPedido.flujo[i].color : ColoresApp.fondo),
                            border: Border.all(
                              color: i <= indiceActual ? Colors.transparent : ColoresApp.bordeFuerte,
                              width: 1.5,
                            ),
                          ),
                          child: i < indiceActual
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : (i == indiceActual ? const Icon(Icons.circle, size: 8, color: Colors.white) : null),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == EstadoPedido.flujo.length - 1
                                ? Colors.transparent
                                : (i < indiceActual ? ColoresApp.verde : ColoresApp.borde),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _cortas[EstadoPedido.flujo[i]]!,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: i == indiceActual ? FontWeight.w700 : FontWeight.w400,
                          color: i <= indiceActual ? ColoresApp.textoTitulo : ColoresApp.textoTenue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Informacion extends StatelessWidget {
  const _Informacion({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final dias = pedido.diasParaEntrega(hoy);
    final filas = <(IconData, String, String)>[
      (Icons.school_outlined, 'Colegio', pedido.colegio.nombre),
      if (pedido.colegio.direccion != null) (Icons.place_outlined, 'Dirección', pedido.colegio.direccion!),
      if (pedido.fechaCreacion != null)
        (
          Icons.event_outlined,
          'Creado',
          // "hace 3 días" solo aporta si es reciente; si no, basta la fecha.
          hoy.difference(pedido.fechaCreacion!).inDays < 30
              ? '${Formatos.fecha(pedido.fechaCreacion!)} (${Formatos.haceCuanto(pedido.fechaCreacion!)})'
              : Formatos.fecha(pedido.fechaCreacion!),
        ),
      if (pedido.fechaEntregaEstimada != null)
        (
          Icons.local_shipping_outlined,
          'Entrega estimada',
          '${Formatos.fecha(pedido.fechaEntregaEstimada!)}'
              '${dias == null || pedido.estado.esFinal ? '' : (dias < 0 ? ' · atrasado ${Formatos.dias(-dias)}' : (dias == 0 ? ' · hoy' : ' · en ${Formatos.dias(dias)}'))}',
        ),
      if (pedido.creadoPor != null) (Icons.person_outline_rounded, 'Creado por', pedido.creadoPor!),
      if (pedido.observaciones != null) (Icons.notes_rounded, 'Observaciones', pedido.observaciones!),
    ];
    return _Seccion(
      titulo: 'Información',
      icono: Icons.info_outline_rounded,
      child: Column(
        children: [
          for (final (icono, titulo, valor) in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icono, size: 18, color: ColoresApp.textoTenue),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    child: Text(titulo, style: const TextStyle(fontSize: 13, color: ColoresApp.textoSecundario)),
                  ),
                  Expanded(
                    child: Text(
                      valor,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: titulo == 'Entrega estimada' && pedido.estaAtrasado(hoy)
                            ? ColoresApp.error
                            : ColoresApp.textoTitulo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Prendas extends StatelessWidget {
  const _Prendas({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Prendas',
      icono: Icons.checkroom_outlined,
      accion: Text(
        '${Formatos.numero(pedido.totalPrendas)} en total',
        style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
      ),
      child: Column(
        children: [
          for (final p in pedido.prendas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 40, maxWidth: 64),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: ColoresApp.infoFondo, borderRadius: BorderRadius.circular(10)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        p.talla ?? '–',
                        maxLines: 1,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: ColoresApp.azulMarino, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.uniforme, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          [p.tipo, p.genero, if (p.talla != null) 'Talla ${p.talla}'].whereType<String>().join(' · '),
                          style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '× ${Formatos.numero(p.cantidad)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (p.disponible == false && p.cantidadMaximaFabricable != null)
                        Text(
                          'alcanza para ${Formatos.numero(p.cantidadMaximaFabricable!)}',
                          style: const TextStyle(fontSize: 11, color: ColoresApp.error),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Resultado de la calculadora textil: ¿alcanza el inventario?
class _CalculoInsumos extends StatelessWidget {
  const _CalculoInsumos({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final porcentaje = pedido.porcentajeCumplimiento;
    final completo = (porcentaje ?? 0) >= 100;
    final faltantes = pedido.insumosNecesarios.where((i) => !i.suficiente).toList();
    return _Seccion(
      titulo: 'Disponibilidad de insumos',
      icono: Icons.calculate_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (porcentaje != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    completo ? 'El inventario alcanza para todo el pedido' : 'El inventario no alcanza por completo',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: completo ? ColoresApp.disponibleTexto : ColoresApp.stockBajoTexto,
                    ),
                  ),
                ),
                Text(
                  '$porcentaje %',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: completo ? ColoresApp.disponibleTexto : ColoresApp.stockBajoTexto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (porcentaje / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: ColoresApp.fondoSuave,
                color: completo ? ColoresApp.verde : ColoresApp.stockBajoPunto,
              ),
            ),
            if (pedido.insumoLimitante != null) ...[
              const SizedBox(height: 8),
              Text(
                'Insumo limitante: ${pedido.insumoLimitante}',
                style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
              ),
            ],
          ],
          if (faltantes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Faltantes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            const SizedBox(height: 6),
            for (final f in faltantes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: ColoresApp.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f.nombre, style: const TextStyle(fontSize: 13))),
                    Text(
                      'faltan ${Formatos.numero(f.faltante)} ${f.unidad}',
                      style: const TextStyle(fontSize: 12.5, color: ColoresApp.error, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Historial extends ConsumerWidget {
  const _Historial({required this.pedidoId});

  final int pedidoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historial = ref.watch(proveedorHistorialPedido(pedidoId));
    return _Seccion(
      titulo: 'Historial',
      icono: Icons.history_rounded,
      child: switch (historial) {
        AsyncValue(:final value?) when value.isEmpty => const Text(
          'Sin cambios registrados.',
          style: TextStyle(color: ColoresApp.textoSecundario),
        ),
        AsyncValue(:final value?) => Column(
          children: [
            for (var i = 0; i < value.length; i++) _EventoHistorial(evento: value[i], esUltimo: i == value.length - 1),
          ],
        ),
        AsyncError(:final error) => Text(
          error is Fallo ? error.mensaje : 'No se pudo cargar el historial.',
          style: const TextStyle(color: ColoresApp.error),
        ),
        _ => const Column(children: [BloqueEsqueleto(alto: 48), SizedBox(height: 8), BloqueEsqueleto(alto: 48)]),
      },
    );
  }
}

class _EventoHistorial extends StatelessWidget {
  const _EventoHistorial({required this.evento, required this.esUltimo});

  final EventoPedido evento;
  final bool esUltimo;

  @override
  Widget build(BuildContext context) {
    final color = evento.estadoNuevo.color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!esUltimo) Expanded(child: Container(width: 2, color: ColoresApp.borde)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.accion, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (evento.observacion != null)
                    Text(
                      evento.observacion!,
                      style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoEtiqueta, height: 1.35),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (evento.realizadoPor != null) evento.realizadoPor!,
                      if (evento.fecha != null) Formatos.haceCuanto(evento.fecha!),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Acciones ──────────────────────────────────────────────────────────────

class _BarraAcciones extends ConsumerStatefulWidget {
  const _BarraAcciones({required this.pedido, required this.rol});

  final Pedido pedido;
  final RolUsuario rol;

  @override
  ConsumerState<_BarraAcciones> createState() => _EstadoBarraAcciones();
}

class _EstadoBarraAcciones extends ConsumerState<_BarraAcciones> {
  bool _procesando = false;

  void _avisar(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: error ? ColoresApp.error : null));
  }

  void _avisarResultado(ResultadoAccion<Pedido> resultado, String exito) => switch (resultado) {
    AccionAplicada() => _avisar(exito),
    AccionEnCola() => _avisar('Sin conexión: el cambio quedó en cola y se enviará al recuperar la red.'),
    AccionFallida(:final fallo) => _avisar(fallo.mensaje, error: true),
  };

  Future<void> _avanzar(AccionPedido accion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(accion.etiqueta),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(accion.confirmacion, style: const TextStyle(height: 1.4)),
            if (accion.afectaStock) ...[
              const SizedBox(height: 14),
              const AvisoEnLinea.informacion('Esta acción modifica el inventario real del taller.'),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: Text(accion.etiqueta)),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => _procesando = true);
    final resultado = await cambiarEstadoPedido(ref, widget.pedido, accion: accion);
    if (!mounted) return;
    setState(() => _procesando = false);
    _avisarResultado(resultado, '${accion.etiqueta}: listo');
  }

  Future<void> _cancelar() async {
    final motivo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _HojaMotivoCancelacion(),
    );
    if (motivo == null || !mounted) return;
    setState(() => _procesando = true);
    final resultado = await cambiarEstadoPedido(ref, widget.pedido, motivoCancelacion: motivo);
    if (!mounted) return;
    setState(() => _procesando = false);
    _avisarResultado(resultado, 'Pedido cancelado');
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.pedido.estado;
    final siguiente = AccionPedido.siguiente(estado);
    final puedeAvanzar = siguiente != null && siguiente.roles.contains(widget.rol);
    final cancelable = puedeCancelar(estado, widget.rol);
    if (!puedeAvanzar && !cancelable) return const SizedBox.shrink();
    final enCola = ref.watch(
      proveedorSincronizacion.select((e) => e.recursosEnCola.contains(recursoDePedido(widget.pedido.id))),
    );
    if (enCola) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: ColoresApp.infoFondo,
          border: Border(top: BorderSide(color: ColoresApp.infoBorde)),
        ),
        child: const SafeArea(
          top: false,
          child: Row(
            children: [
              Icon(Icons.schedule_send_rounded, color: ColoresApp.azulMedio),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hay un cambio de este pedido en la bandeja de salida. Se enviará al recuperar la conexión.',
                  style: TextStyle(color: ColoresApp.azulMedio, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: ColoresApp.fondo,
        border: Border(top: BorderSide(color: ColoresApp.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (cancelable)
              OutlinedButton(
                onPressed: _procesando ? null : _cancelar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresApp.error,
                  side: const BorderSide(color: ColoresApp.errorBorde, width: 1.5),
                ),
                child: const Text('Cancelar'),
              ),
            if (cancelable && puedeAvanzar) const SizedBox(width: 10),
            if (puedeAvanzar)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _procesando ? null : () => _avanzar(siguiente),
                  icon: _procesando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: ColoresApp.textoTenue),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(siguiente.etiqueta),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HojaMotivoCancelacion extends StatefulWidget {
  const _HojaMotivoCancelacion();

  @override
  State<_HojaMotivoCancelacion> createState() => _EstadoHojaMotivoCancelacion();
}

class _EstadoHojaMotivoCancelacion extends State<_HojaMotivoCancelacion> {
  final _llave = GlobalKey<FormState>();
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _llave,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Cancelar pedido', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Si el pedido ya estaba en producción, el stock descontado vuelve al inventario. '
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: ColoresApp.textoSecundario, height: 1.4),
            ),
            const SizedBox(height: 18),
            CampoConEtiqueta(
              etiqueta: 'Motivo',
              obligatorio: true,
              campo: TextFormField(
                controller: _controlador,
                autofocus: true,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Ej.: el colegio anuló la compra'),
                validator: (v) => (v == null || v.trim().length < 5) ? 'Escribe el motivo (mín. 5 caracteres)' : null,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ColoresApp.error),
              onPressed: () {
                if (_llave.currentState?.validate() ?? false) Navigator.pop(context, _controlador.text.trim());
              },
              child: const Text('Cancelar pedido'),
            ),
          ],
        ),
      ),
    );
  }
}
