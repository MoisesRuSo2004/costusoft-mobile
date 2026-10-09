import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../autenticacion/dominio/estado_sesion.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../../pedidos/dominio/pedido.dart';
import '../datos/fuente_remota_institucion.dart';
import '../datos/repositorio_institucion_impl.dart';
import '../dominio/perfil_institucion.dart';
import '../dominio/repositorio_institucion.dart';

final proveedorRepositorioInstitucion = Provider<RepositorioInstitucion>(
  (ref) => RepositorioInstitucionImpl(FuenteRemotaInstitucion(ref.watch(proveedorClienteHttp))),
);

T _datosOLanzar<T>(Resultado<T> resultado) => switch (resultado) {
  Exito(:final datos) => datos,
  Falla(:final fallo) => throw fallo,
};

/// Id del usuario en sesión: los datos del colegio se descartan al cambiar.
int? _usuarioActual(Ref ref) => ref.watch(proveedorSesion.select((s) => s is SesionActiva ? s.usuario.id : null));

final proveedorPerfilInstitucion = FutureProvider<PerfilInstitucion>((ref) async {
  _usuarioActual(ref);
  return _datosOLanzar(await ref.read(proveedorRepositorioInstitucion).perfil());
});

// ── Pedidos del colegio (paginados: un colegio puede tener cientos) ───────

class PedidosInstitucion {
  const PedidosInstitucion({
    required this.pedidos,
    required this.paginaActual,
    required this.hayMas,
    this.cargandoMas = false,
    this.errorAlCargarMas,
  });

  final List<Pedido> pedidos;
  final int paginaActual;
  final bool hayMas;
  final bool cargandoMas;
  final String? errorAlCargarMas;

  /// Pedidos que siguen su curso (ni entregados ni cancelados).
  List<Pedido> get enCurso => [
    for (final p in pedidos)
      if (!p.estado.esFinal) p,
  ];

  List<Pedido> get finalizados => [
    for (final p in pedidos)
      if (p.estado.esFinal) p,
  ];

  PedidosInstitucion copiarCon({
    List<Pedido>? pedidos,
    int? paginaActual,
    bool? hayMas,
    bool? cargandoMas,
    String? error,
  }) => PedidosInstitucion(
    pedidos: pedidos ?? this.pedidos,
    paginaActual: paginaActual ?? this.paginaActual,
    hayMas: hayMas ?? this.hayMas,
    cargandoMas: cargandoMas ?? this.cargandoMas,
    errorAlCargarMas: error,
  );
}

final proveedorPedidosInstitucion = AsyncNotifierProvider<ControladorPedidosInstitucion, PedidosInstitucion>(
  ControladorPedidosInstitucion.new,
);

class ControladorPedidosInstitucion extends AsyncNotifier<PedidosInstitucion> {
  /// Página amplia: los pedidos en curso suelen ser los más recientes.
  static const _tamano = 30;

  RepositorioInstitucion get _repositorio => ref.read(proveedorRepositorioInstitucion);

  @override
  Future<PedidosInstitucion> build() async {
    _usuarioActual(ref);
    final pagina = _datosOLanzar(await _repositorio.listarPedidos(pagina: 0, tamano: _tamano));
    return PedidosInstitucion(pedidos: pagina.contenido, paginaActual: 0, hayMas: pagina.hayMasPaginas);
  }

  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hayMas || actual.cargandoMas) return;
    state = AsyncData(actual.copiarCon(cargandoMas: true));
    final resultado = await _repositorio.listarPedidos(pagina: actual.paginaActual + 1, tamano: _tamano);
    state = AsyncData(switch (resultado) {
      Exito(:final datos) => actual.copiarCon(
        pedidos: [...actual.pedidos, ...datos.contenido.where((p) => actual.pedidos.every((q) => q.id != p.id))],
        paginaActual: actual.paginaActual + 1,
        hayMas: datos.hayMasPaginas,
        cargandoMas: false,
      ),
      Falla(:final fallo) => actual.copiarCon(cargandoMas: false, error: fallo.mensaje),
    });
  }
}

// ── Seguimiento de un pedido ──────────────────────────────────────────────

final proveedorPedidoInstitucion = FutureProvider.autoDispose.family<Pedido, int>(
  (ref, id) async => _datosOLanzar(await ref.read(proveedorRepositorioInstitucion).obtenerPedido(id)),
);

final proveedorHistorialInstitucion = FutureProvider.autoDispose.family<List<EventoPedido>, int>(
  (ref, id) async => _datosOLanzar(await ref.read(proveedorRepositorioInstitucion).historial(id)),
);
