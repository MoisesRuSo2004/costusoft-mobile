import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/marco_navegacion.dart';
import '../../modulos/autenticacion/dominio/estado_sesion.dart';
import '../../modulos/autenticacion/presentacion/controlador_sesion.dart';
import '../../modulos/autenticacion/presentacion/pagina_ingreso.dart';
import '../../modulos/bodega/presentacion/pagina_escanear.dart';
import '../../modulos/bodega/presentacion/pagina_movimientos.dart';
import '../../modulos/bodega/presentacion/pagina_pendientes.dart';
import '../../modulos/bodega/presentacion/proveedores_bodega.dart';
import '../../modulos/carga/presentacion/pagina_carga.dart';
import '../../modulos/ia/presentacion/pagina_ia.dart';
import '../../modulos/institucion/presentacion/pagina_asistente_institucional.dart';
import '../../modulos/institucion/presentacion/pagina_mis_pedidos.dart';
import '../../modulos/institucion/presentacion/pagina_seguimiento_pedido.dart';
import '../../modulos/inventario/presentacion/pagina_detalle_insumo.dart';
import '../../modulos/inventario/presentacion/pagina_inventario.dart';
import '../../modulos/pedidos/dominio/pedido.dart';
import '../../modulos/pedidos/presentacion/pagina_detalle_pedido.dart';
import '../../modulos/pedidos/presentacion/pagina_pedidos.dart';
import '../../modulos/perfil/presentacion/pagina_perfil.dart';
import '../../modulos/tablero/presentacion/pagina_inicio.dart';
import 'guardia_rutas.dart';
import 'rutas_app.dart';

/// Avisa al enrutador cada vez que cambia la sesión para que recalcule la
/// redirección (iniciar sesión, cerrar sesión o sesión expirada).
class _AvisoCambioSesion extends ChangeNotifier {
  void avisar() => notifyListeners();
}

final proveedorEnrutador = Provider<GoRouter>((ref) {
  final aviso = _AvisoCambioSesion();
  ref.listen(proveedorSesion, (_, _) => aviso.avisar());

  // Ruta pedida antes de restaurar la sesión (enlace directo o recarga de la
  // página): se recuerda para llevar allí al usuario y no siempre al inicio.
  String? rutaSolicitada;

  final enrutador = GoRouter(
    initialLocation: RutasApp.carga,
    refreshListenable: aviso,
    redirect: (_, estadoRuta) {
      final estado = ref.read(proveedorSesion);
      final ubicacion = estadoRuta.matchedLocation;
      if (estado is SesionPendiente && ubicacion != RutasApp.carga) rutaSolicitada = estadoRuta.uri.path;
      final destino = calcularRedireccion(estado, ubicacion, rutaSolicitada: rutaSolicitada);
      if (estado is! SesionPendiente) rutaSolicitada = null;
      return destino;
    },
    routes: [
      GoRoute(path: RutasApp.carga, builder: (_, _) => const PaginaCarga()),
      GoRoute(path: RutasApp.ingreso, builder: (_, _) => const PaginaIngreso()),
      _rutasAdministrador(),
      _rutasBodega(),
      _rutasInstitucion(),
    ],
  );
  ref.onDispose(() {
    enrutador.dispose();
    aviso.dispose();
  });
  return enrutador;
});

GoRoute _pestana(String ruta, Widget pagina) => GoRoute(path: ruta, builder: (_, _) => pagina);

StatefulShellBranch _rama(String ruta, Widget pagina) => StatefulShellBranch(routes: [_pestana(ruta, pagina)]);

StatefulShellRoute _rutasAdministrador() => StatefulShellRoute.indexedStack(
  builder: (_, _, navegacion) => MarcoNavegacion(
    navegacion: navegacion,
    destinos: const [
      DestinoNavegacion(
        etiqueta: 'Inicio',
        icono: Icons.space_dashboard_outlined,
        iconoSeleccionado: Icons.space_dashboard,
      ),
      DestinoNavegacion(
        etiqueta: 'Inventario',
        icono: Icons.inventory_2_outlined,
        iconoSeleccionado: Icons.inventory_2,
      ),
      DestinoNavegacion(etiqueta: 'IA', icono: Icons.auto_awesome_outlined, iconoSeleccionado: Icons.auto_awesome),
      DestinoNavegacion(etiqueta: 'Pedidos', icono: Icons.receipt_long_outlined, iconoSeleccionado: Icons.receipt_long),
      DestinoNavegacion(
        etiqueta: 'Perfil',
        icono: Icons.person_outline_rounded,
        iconoSeleccionado: Icons.person_rounded,
      ),
    ],
  ),
  branches: [
    _rama(RutasApp.adminInicio, const PaginaInicio()),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RutasApp.adminInventario,
          builder: (_, _) => const PaginaInventario(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, estado) => PaginaDetalleInsumo(insumoId: int.tryParse(estado.pathParameters['id']!) ?? 0),
            ),
          ],
        ),
      ],
    ),
    _rama(RutasApp.adminIa, const PaginaIa()),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RutasApp.adminPedidos,
          builder: (_, _) => const PaginaPedidos(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, estado) => PaginaDetallePedido(pedidoId: int.tryParse(estado.pathParameters['id']!) ?? 0),
            ),
          ],
        ),
      ],
    ),
    _rama(RutasApp.adminPerfil, const PaginaPerfil()),
  ],
);

StatefulShellRoute _rutasBodega() => StatefulShellRoute.indexedStack(
  builder: (_, _, navegacion) => MarcoNavegacion(
    navegacion: navegacion,
    destinos: const [
      DestinoNavegacion(
        etiqueta: 'Pendientes',
        icono: Icons.pending_actions_outlined,
        iconoSeleccionado: Icons.pending_actions,
      ),
      DestinoNavegacion(
        etiqueta: 'Escanear',
        icono: Icons.qr_code_scanner_outlined,
        iconoSeleccionado: Icons.qr_code_scanner,
      ),
      DestinoNavegacion(
        etiqueta: 'Inventario',
        icono: Icons.inventory_2_outlined,
        iconoSeleccionado: Icons.inventory_2,
      ),
      DestinoNavegacion(etiqueta: 'Movimientos', icono: Icons.swap_vert_outlined, iconoSeleccionado: Icons.swap_vert),
      DestinoNavegacion(
        etiqueta: 'Perfil',
        icono: Icons.person_outline_rounded,
        iconoSeleccionado: Icons.person_rounded,
      ),
    ],
  ),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RutasApp.bodegaPendientes,
          builder: (_, _) => const PaginaPendientes(),
          routes: [
            GoRoute(
              path: 'pedido/:id',
              builder: (_, estado) => PaginaDetallePedido(pedidoId: int.tryParse(estado.pathParameters['id']!) ?? 0),
            ),
            // Cola completa de un estado, paginada (Bodega solo ve sus tres estados).
            GoRoute(
              path: 'pedidos',
              builder: (_, estado) => PaginaPedidos(
                estados: estadosPedidoBodega,
                estadoInicial: EstadoPedido.values
                    .where((e) => e.codigo == estado.uri.queryParameters['estado'])
                    .firstOrNull,
              ),
            ),
          ],
        ),
      ],
    ),
    _rama(RutasApp.bodegaEscanear, const PaginaEscanear()),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RutasApp.bodegaInventario,
          builder: (_, _) => const PaginaInventario(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, estado) => PaginaDetalleInsumo(insumoId: int.tryParse(estado.pathParameters['id']!) ?? 0),
            ),
          ],
        ),
      ],
    ),
    _rama(RutasApp.bodegaMovimientos, const PaginaMovimientos()),
    _rama(RutasApp.bodegaPerfil, const PaginaPerfil()),
  ],
);

StatefulShellRoute _rutasInstitucion() => StatefulShellRoute.indexedStack(
  builder: (_, _, navegacion) => MarcoNavegacion(
    navegacion: navegacion,
    destinos: const [
      DestinoNavegacion(
        etiqueta: 'Mis pedidos',
        icono: Icons.receipt_long_outlined,
        iconoSeleccionado: Icons.receipt_long,
      ),
      DestinoNavegacion(
        etiqueta: 'Asistente',
        icono: Icons.auto_awesome_outlined,
        iconoSeleccionado: Icons.auto_awesome,
      ),
      DestinoNavegacion(
        etiqueta: 'Perfil',
        icono: Icons.person_outline_rounded,
        iconoSeleccionado: Icons.person_rounded,
      ),
    ],
  ),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RutasApp.institucionPedidos,
          builder: (_, _) => const PaginaMisPedidos(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, estado) =>
                  PaginaSeguimientoPedido(pedidoId: int.tryParse(estado.pathParameters['id']!) ?? 0),
            ),
          ],
        ),
      ],
    ),
    _rama(RutasApp.institucionAsistente, const PaginaAsistenteInstitucional()),
    _rama(RutasApp.institucionPerfil, const PaginaPerfil()),
  ],
);
