import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../compartido/widgets/encabezado_rol.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/notificaciones/controlador_avisos.dart';
import '../../../nucleo/notificaciones/servicio_notificaciones.dart';
import '../../../nucleo/rutas/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/paleta_rol.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../pedidos/dominio/pedido.dart';
import '../../pedidos/presentacion/estilos_pedidos.dart';
import '../../pedidos/presentacion/tarjeta_pedido.dart';
import '../dominio/seguimiento_pedido.dart';
import 'proveedores_institucion.dart';

/// Inicio del coordinador: pedidos de su colegio. Primero los que siguen en
/// curso (con su avance) y debajo los anteriores, paginados.
class PaginaMisPedidos extends ConsumerWidget {
  const PaginaMisPedidos({super.key});

  Future<void> _actualizar(WidgetRef ref) async {
    ref
      ..invalidate(proveedorPerfilInstitucion)
      ..invalidate(proveedorPedidosInstitucion);
    try {
      await ref.read(proveedorPedidosInstitucion.future);
    } on Object {
      // Se muestra en pantalla.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(proveedorPerfilInstitucion).value;
    final pedidos = ref.watch(proveedorPedidosInstitucion);
    final paleta = ref.watch(proveedorPaletaRol);
    final listos = pedidos.value?.enCurso.where((p) => p.estado == EstadoPedido.listoParaEntrega).toList();

    void abrir(Pedido p) => context.push(RutasApp.institucionSeguimiento(p.id));

    return Scaffold(
      backgroundColor: ColoresApp.fondoSuave,
      body: RefreshIndicator(
        color: paleta.acento,
        onRefresh: () => _actualizar(ref),
        child: NotificationListener<ScrollNotification>(
          // Al acercarse al final se pide la siguiente página.
          onNotification: (aviso) {
            if (aviso.metrics.extentAfter < 400) ref.read(proveedorPedidosInstitucion.notifier).cargarMas();
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              EncabezadoRol(
                estado: ChipEncabezado(
                  icono: Icons.school_outlined,
                  colorIcono: paleta.indicador,
                  texto: perfil?.nombreColegio ?? paleta.nombre,
                ),
                cifras: [
                  CifraEncabezado(valor: perfil?.pedidosActivos, etiqueta: 'En curso'),
                  CifraEncabezado(valor: listos?.length, etiqueta: 'Listos'),
                  CifraEncabezado(valor: perfil?.totalPedidos, etiqueta: 'Total'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: switch (pedidos) {
                  AsyncValue(:final value?) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TarjetaAvisos(),
                      if (listos != null && listos.isNotEmpty) ...[
                        _AvisoListos(listos: listos, alTocar: () => abrir(listos.first)),
                        const SizedBox(height: 20),
                      ],
                      const _Titulo('Pedidos en curso'),
                      if (value.enCurso.isEmpty)
                        const _SinPedidos(texto: 'No tienes pedidos en curso en este momento.')
                      else
                        for (final p in value.enCurso)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TarjetaEnCurso(pedido: p, acento: paleta.acento, alTocar: () => abrir(p)),
                          ),
                      if (value.finalizados.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const _Titulo('Pedidos anteriores'),
                        for (final p in value.finalizados)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TarjetaPedido(pedido: p, mostrarColegio: false, alTocar: () => abrir(p)),
                          ),
                      ],
                      if (value.cargandoMas)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                        )
                      else if (value.errorAlCargarMas case final error?)
                        TextButton.icon(
                          onPressed: ref.read(proveedorPedidosInstitucion.notifier).cargarMas,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('$error Toca para reintentar.'),
                        ),
                    ],
                  ),
                  AsyncError(:final error) => EstadoError(
                    mensaje: error is Fallo ? error.mensaje : 'No se pudieron cargar tus pedidos.',
                    alReintentar: () => _actualizar(ref),
                  ),
                  _ => const Column(
                    children: [
                      BloqueEsqueleto(alto: 120, radio: 14),
                      SizedBox(height: 10),
                      BloqueEsqueleto(alto: 120, radio: 14),
                    ],
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  );
}

class _SinPedidos extends StatelessWidget {
  const _SinPedidos({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ColoresApp.fondo,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ColoresApp.borde),
    ),
    child: Text(texto, style: const TextStyle(color: ColoresApp.textoSecundario)),
  );
}

/// "¡Tienes N pedidos listos para entrega!" en verde, el estado que más
/// le importa al colegio.
class _AvisoListos extends StatelessWidget {
  const _AvisoListos({required this.listos, required this.alTocar});

  final List<Pedido> listos;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    const estado = EstadoPedido.listoParaEntrega;
    return Material(
      color: estado.fondo,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: estado.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: estado.color, shape: BoxShape.circle),
                child: Icon(estado.icono, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listos.length == 1
                          ? '¡Tu pedido ${listos.first.numero} está listo!'
                          : '¡Tienes ${listos.length} pedidos listos para entrega!',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: estado.color),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Los uniformes están listos para entregar en el colegio.',
                      style: TextStyle(fontSize: 12.5, color: ColoresApp.textoEtiqueta),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: estado.color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pedido en curso: estado, frase del seguimiento y barra de avance por hitos.
class _TarjetaEnCurso extends StatelessWidget {
  const _TarjetaEnCurso({required this.pedido, required this.acento, required this.alTocar});

  final Pedido pedido;
  final Color acento;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final hitos = calcularHitos(pedido, const []);
    final alcanzados = hitos.where((h) => h.situacion != SituacionHito.pendiente).length;
    final dias = pedido.diasParaEntrega(DateTime.now());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(pedido.numero, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  pedido.estado.insignia,
                ],
              ),
              const SizedBox(height: 6),
              Text(
                mensajeDeSeguimiento(pedido.estado),
                style: const TextStyle(fontSize: 13, color: ColoresApp.textoEtiqueta),
              ),
              const SizedBox(height: 12),
              // Un segmento por hito: los alcanzados con el color del rol.
              Row(
                children: [
                  for (var i = 0; i < hitos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: i < alcanzados
                              ? (i == alcanzados - 1 ? pedido.estado.color : acento)
                              : ColoresApp.borde,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.checkroom_outlined, size: 14, color: ColoresApp.textoSecundario),
                  const SizedBox(width: 4),
                  Text(
                    '${Formatos.numero(pedido.totalPrendas)} ${pedido.totalPrendas == 1 ? 'prenda' : 'prendas'}',
                    style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
                  ),
                  const Spacer(),
                  if (dias != null && dias >= 0 && pedido.estado != EstadoPedido.listoParaEntrega)
                    Text(
                      dias == 0 ? 'Entrega estimada hoy' : 'Entrega estimada en ${Formatos.dias(dias)}',
                      style: TextStyle(fontSize: 12.5, color: acento, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Invita a activar los avisos push ("tu pedido está listo"). El permiso se
/// pide al tocar el botón: los navegadores lo exigen así y es más claro para
/// el usuario saber para qué se le pide.
class _TarjetaAvisos extends ConsumerWidget {
  const _TarjetaAvisos();

  Future<void> _activar(BuildContext context, WidgetRef ref) async {
    await ref.read(proveedorAvisos.notifier).activar();
    if (!context.mounted) return;
    final activos = ref.read(proveedorAvisos).value == EstadoAvisos.activos;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activos
              ? 'Listo: te avisaremos cuando tus pedidos estén listos.'
              : 'No se activaron los avisos. Puedes hacerlo luego desde la configuración.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avisos = ref.watch(proveedorAvisos);
    final acento = ref.watch(proveedorPaletaRol).acento;
    final (titulo, texto, mostrarBoton) = switch (avisos.value) {
      EstadoAvisos.sinPreguntar => (
        'Activa los avisos',
        'Te avisamos al instante cuando tus uniformes estén listos para entrega.',
        true,
      ),
      EstadoAvisos.bloqueados => (
        'Avisos bloqueados',
        'Para recibirlos, permite las notificaciones de CostuSoft en la configuración del teléfono o del navegador.',
        false,
      ),
      _ => (null, null, false),
    };
    if (titulo == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: ref.watch(proveedorPaletaRol).acentoSuave,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: acento.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              mostrarBoton ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
              color: acento,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(texto!, style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoEtiqueta, height: 1.35)),
                ],
              ),
            ),
            if (mostrarBoton) ...[
              const SizedBox(width: 10),
              FilledButton(
                onPressed: avisos.isLoading ? null : () => _activar(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: acento,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Activar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
