import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../../nucleo/sin_conexion/acciones_sin_conexion.dart';
import '../../../nucleo/sin_conexion/bandeja_salida.dart';
import '../../inventario/presentacion/proveedores_inventario.dart';
import '../../tablero/presentacion/proveedores_tablero.dart';
import '../datos/fuente_remota_pedidos.dart';
import '../datos/repositorio_pedidos_impl.dart';
import '../dominio/pedido.dart';
import '../dominio/repositorio_pedidos.dart';

final proveedorRepositorioPedidos = Provider<RepositorioPedidos>(
  (ref) => RepositorioPedidosImpl(FuenteRemotaPedidos(ref.watch(proveedorClienteHttp))),
);

T _datosOLanzar<T>(Resultado<T> resultado) => switch (resultado) {
  Exito(:final datos) => datos,
  Falla(:final fallo) => throw fallo,
};

// ── Filtros (se aplican en el servidor) ───────────────────────────────────

class FiltroPedidos {
  const FiltroPedidos({this.estado, this.colegioId, this.nombreColegio});

  final EstadoPedido? estado;
  final int? colegioId;
  final String? nombreColegio;

  bool get estaActivo => estado != null || colegioId != null;
}

final proveedorFiltroPedidos = NotifierProvider<ControladorFiltroPedidos, FiltroPedidos>(ControladorFiltroPedidos.new);

class ControladorFiltroPedidos extends Notifier<FiltroPedidos> {
  @override
  FiltroPedidos build() => const FiltroPedidos();

  void elegirEstado(EstadoPedido? estado) =>
      state = FiltroPedidos(estado: estado, colegioId: state.colegioId, nombreColegio: state.nombreColegio);

  void elegirColegio(int? id, String? nombre) =>
      state = FiltroPedidos(estado: state.estado, colegioId: id, nombreColegio: nombre);

  void limpiar() => state = const FiltroPedidos();
}

// ── Lista paginada ────────────────────────────────────────────────────────

/// Pedidos ya cargados y si quedan más páginas en el servidor.
class ListaPedidos {
  const ListaPedidos({
    required this.pedidos,
    required this.paginaActual,
    required this.total,
    required this.hayMas,
    this.cargandoMas = false,
    this.errorAlCargarMas,
  });

  final List<Pedido> pedidos;
  final int paginaActual;
  final int total;
  final bool hayMas;
  final bool cargandoMas;
  final String? errorAlCargarMas;

  ListaPedidos copiarCon({List<Pedido>? pedidos, int? paginaActual, bool? hayMas, bool? cargandoMas, String? error}) =>
      ListaPedidos(
        pedidos: pedidos ?? this.pedidos,
        paginaActual: paginaActual ?? this.paginaActual,
        total: total,
        hayMas: hayMas ?? this.hayMas,
        cargandoMas: cargandoMas ?? this.cargandoMas,
        errorAlCargarMas: error,
      );
}

final proveedorListaPedidos = AsyncNotifierProvider<ControladorListaPedidos, ListaPedidos>(ControladorListaPedidos.new);

class ControladorListaPedidos extends AsyncNotifier<ListaPedidos> {
  RepositorioPedidos get _repositorio => ref.read(proveedorRepositorioPedidos);

  @override
  Future<ListaPedidos> build() async {
    // Al cambiar el filtro se vuelve a la primera página.
    final filtro = ref.watch(proveedorFiltroPedidos);
    final pagina = _datosOLanzar(
      await _repositorio.listar(pagina: 0, estado: filtro.estado, colegioId: filtro.colegioId),
    );
    return ListaPedidos(
      pedidos: pagina.contenido,
      paginaActual: 0,
      total: pagina.totalElementos,
      hayMas: pagina.hayMasPaginas,
    );
  }

  /// Carga la siguiente página (al llegar al final de la lista).
  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hayMas || actual.cargandoMas) return;
    state = AsyncData(actual.copiarCon(cargandoMas: true));

    final filtro = ref.read(proveedorFiltroPedidos);
    final resultado = await _repositorio.listar(
      pagina: actual.paginaActual + 1,
      estado: filtro.estado,
      colegioId: filtro.colegioId,
    );
    state = AsyncData(switch (resultado) {
      Exito(:final datos) => actual.copiarCon(
        // Evita duplicados si llegaron pedidos nuevos entre páginas.
        pedidos: [...actual.pedidos, ...datos.contenido.where((p) => actual.pedidos.every((q) => q.id != p.id))],
        paginaActual: actual.paginaActual + 1,
        hayMas: datos.hayMasPaginas,
        cargandoMas: false,
      ),
      Falla(:final fallo) => actual.copiarCon(cargandoMas: false, error: fallo.mensaje),
    });
  }

  /// Reemplaza un pedido de la lista tras cambiar su estado. Si con el filtro
  /// actual ya no corresponde (p. ej. filtrado por "Confirmado"), se quita.
  void reemplazar(Pedido pedido) {
    final actual = state.value;
    if (actual == null) return;
    final filtro = ref.read(proveedorFiltroPedidos);
    final sigueEnFiltro = filtro.estado == null || filtro.estado == pedido.estado;
    state = AsyncData(
      actual.copiarCon(
        pedidos: [
          for (final p in actual.pedidos)
            if (p.id != pedido.id) p else if (sigueEnFiltro) pedido,
        ],
      ),
    );
  }
}

// ── Detalle ───────────────────────────────────────────────────────────────

final proveedorPedido = FutureProvider.autoDispose.family<Pedido, int>(
  (ref, id) async => _datosOLanzar(await ref.read(proveedorRepositorioPedidos).obtener(id)),
);

final proveedorHistorialPedido = FutureProvider.autoDispose.family<List<EventoPedido>, int>(
  (ref, id) async => _datosOLanzar(await ref.read(proveedorRepositorioPedidos).historial(id)),
);

/// Recurso de la bandeja de salida para un pedido.
String recursoDePedido(int pedidoId) => 'pedidos/$pedidoId';

/// Refresca la lista, el detalle, el historial y los contadores del Inicio
/// tras un cambio de estado; con [afectaStock], también el inventario.
void invalidarTrasCambiarPedido(Invalidador invalidar, int pedidoId, {bool afectaStock = false}) {
  invalidar(proveedorPedido(pedidoId));
  invalidar(proveedorHistorialPedido(pedidoId));
  invalidar(proveedorConteoPedidos);
  invalidar(proveedorResumenTablero);
  if (afectaStock) {
    // Iniciar producción descuenta stock y cancelar puede devolverlo.
    invalidar(proveedorInsumos);
    invalidar(proveedorPredicciones);
  }
}

/// Avanza el pedido con [accion] o, con [motivoCancelacion], lo cancela.
/// Sin conexión, el cambio queda en la bandeja de salida.
Future<ResultadoAccion<Pedido>> cambiarEstadoPedido(
  WidgetRef ref,
  Pedido pedido, {
  AccionPedido? accion,
  String? motivoCancelacion,
}) async {
  assert((accion == null) != (motivoCancelacion == null), 'Indica una acción o un motivo de cancelación');
  final repositorio = ref.read(proveedorRepositorioPedidos);
  final motivo = motivoCancelacion?.trim();
  final resultado = await ejecutarOEncolar(
    ref,
    solicitud: SolicitudPendiente(
      metodo: 'POST',
      ruta: '/api/pedidos/${pedido.id}/${accion?.ruta ?? 'cancelar'}',
      cuerpo: motivo == null ? null : {'motivo': motivo},
      recurso: recursoDePedido(pedido.id),
      descripcion: '${accion?.etiqueta ?? 'Cancelar'} · ${pedido.numero}',
    ),
    enviar: () => accion != null ? repositorio.ejecutar(pedido.id, accion) : repositorio.cancelar(pedido.id, motivo!),
  );
  if (resultado case AccionAplicada(:final datos)) {
    ref.read(proveedorListaPedidos.notifier).reemplazar(datos);
    invalidarTrasCambiarPedido(ref.invalidate, pedido.id, afectaStock: accion?.afectaStock ?? true);
  }
  return resultado;
}
