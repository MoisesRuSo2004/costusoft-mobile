import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../../nucleo/red/respuesta_api.dart';
import '../../../nucleo/sin_conexion/acciones_sin_conexion.dart';
import '../../../nucleo/sin_conexion/bandeja_salida.dart';
import '../../inventario/presentacion/proveedores_inventario.dart';
import '../../pedidos/dominio/pedido.dart';
import '../../pedidos/presentacion/proveedores_pedidos.dart';
import '../../tablero/presentacion/proveedores_tablero.dart';
import '../datos/repositorio_movimientos_impl.dart';
import '../dominio/movimiento.dart';
import '../dominio/repositorio_movimientos.dart';

final proveedorRepositorioMovimientos = Provider<RepositorioMovimientos>(
  (ref) => RepositorioMovimientosImpl(ref.watch(proveedorClienteHttp)),
);

T _datosOLanzar<T>(Resultado<T> resultado) => switch (resultado) {
  Exito(:final datos) => datos,
  Falla(:final fallo) => throw fallo,
};

// ── Cola de trabajo ───────────────────────────────────────────────────────

/// Entradas y salidas esperando la verificación de Bodega.
class MovimientosPendientes {
  const MovimientosPendientes({
    required this.entradas,
    required this.salidas,
    required this.totalEntradas,
    required this.totalSalidas,
  });

  final List<Movimiento> entradas;
  final List<Movimiento> salidas;
  final int totalEntradas;
  final int totalSalidas;

  int get total => totalEntradas + totalSalidas;

  /// Pendientes que incluyen un insumo (para el escáner).
  List<Movimiento> conInsumo(int insumoId) =>
      [...entradas, ...salidas].where((m) => m.incluyeInsumo(insumoId)).toList();
}

final proveedorMovimientosPendientes = FutureProvider<MovimientosPendientes>((ref) async {
  final repositorio = ref.read(proveedorRepositorioMovimientos);
  final (entradas, salidas) = await (
    repositorio.listar(TipoMovimiento.entrada, pagina: 0, tamano: 50, estado: EstadoMovimiento.pendiente),
    repositorio.listar(TipoMovimiento.salida, pagina: 0, tamano: 50, estado: EstadoMovimiento.pendiente),
  ).wait;
  final e = _datosOLanzar(entradas);
  final s = _datosOLanzar(salidas);
  return MovimientosPendientes(
    entradas: e.contenido,
    salidas: s.contenido,
    totalEntradas: e.totalElementos,
    totalSalidas: s.totalElementos,
  );
});

/// Pedidos que Bodega puede hacer avanzar.
///
/// La cola muestra una vista previa por estado; "Ver todos" abre la lista
/// paginada en el servidor.
const estadosPedidoBodega = [EstadoPedido.confirmado, EstadoPedido.enProduccion, EstadoPedido.listoParaEntrega];

const pedidosPorEstadoEnCola = 3;

final proveedorPedidosPorAtender = FutureProvider<Map<EstadoPedido, PaginaApi<Pedido>>>((ref) async {
  final repositorio = ref.read(proveedorRepositorioPedidos);
  final paginas = await Future.wait([
    for (final estado in estadosPedidoBodega)
      repositorio.listar(pagina: 0, tamano: pedidosPorEstadoEnCola, estado: estado),
  ]);
  return {for (var i = 0; i < estadosPedidoBodega.length; i++) estadosPedidoBodega[i]: _datosOLanzar(paginas[i])};
});

// ── Historial de movimientos (paginado en el servidor) ───────────────────

class FiltroMovimientos {
  const FiltroMovimientos({this.tipo = TipoMovimiento.entrada, this.estado});

  final TipoMovimiento tipo;
  final EstadoMovimiento? estado;
}

final proveedorFiltroMovimientos = NotifierProvider<ControladorFiltroMovimientos, FiltroMovimientos>(
  ControladorFiltroMovimientos.new,
);

class ControladorFiltroMovimientos extends Notifier<FiltroMovimientos> {
  @override
  FiltroMovimientos build() => const FiltroMovimientos();

  void elegirTipo(TipoMovimiento tipo) => state = FiltroMovimientos(tipo: tipo, estado: state.estado);

  void elegirEstado(EstadoMovimiento? estado) => state = FiltroMovimientos(tipo: state.tipo, estado: estado);
}

class ListaMovimientos {
  const ListaMovimientos({
    required this.movimientos,
    required this.pagina,
    required this.total,
    required this.hayMas,
    this.cargandoMas = false,
    this.error,
  });

  final List<Movimiento> movimientos;
  final int pagina;
  final int total;
  final bool hayMas;
  final bool cargandoMas;
  final String? error;
}

final proveedorHistorialMovimientos = AsyncNotifierProvider<ControladorHistorialMovimientos, ListaMovimientos>(
  ControladorHistorialMovimientos.new,
);

class ControladorHistorialMovimientos extends AsyncNotifier<ListaMovimientos> {
  @override
  Future<ListaMovimientos> build() async {
    final filtro = ref.watch(proveedorFiltroMovimientos);
    final pagina = _datosOLanzar(
      await ref.read(proveedorRepositorioMovimientos).listar(filtro.tipo, pagina: 0, estado: filtro.estado),
    );
    return ListaMovimientos(
      movimientos: pagina.contenido,
      pagina: 0,
      total: pagina.totalElementos,
      hayMas: pagina.hayMasPaginas,
    );
  }

  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hayMas || actual.cargandoMas) return;
    state = AsyncData(
      ListaMovimientos(
        movimientos: actual.movimientos,
        pagina: actual.pagina,
        total: actual.total,
        hayMas: true,
        cargandoMas: true,
      ),
    );
    final filtro = ref.read(proveedorFiltroMovimientos);
    final resultado = await ref
        .read(proveedorRepositorioMovimientos)
        .listar(filtro.tipo, pagina: actual.pagina + 1, estado: filtro.estado);
    state = AsyncData(switch (resultado) {
      Exito(:final datos) => ListaMovimientos(
        movimientos: [
          ...actual.movimientos,
          ...datos.contenido.where((m) => actual.movimientos.every((x) => x.id != m.id)),
        ],
        pagina: actual.pagina + 1,
        total: actual.total,
        hayMas: datos.hayMasPaginas,
      ),
      Falla(:final fallo) => ListaMovimientos(
        movimientos: actual.movimientos,
        pagina: actual.pagina,
        total: actual.total,
        hayMas: true,
        error: fallo.mensaje,
      ),
    });
  }
}

// ── Verificación (confirmar / rechazar) ───────────────────────────────────

/// Recurso de la bandeja de salida para un movimiento, p. ej. `entradas/12`.
String recursoDeMovimiento(Movimiento m) => '${m.tipo.ruta}/${m.id}';

/// Refresca todo lo que depende del stock tras confirmar o rechazar.
void invalidarTrasVerificar(Invalidador invalidar) {
  invalidar(proveedorMovimientosPendientes);
  invalidar(proveedorHistorialMovimientos);
  invalidar(proveedorInsumos);
  invalidar(proveedorPredicciones);
  invalidar(proveedorResumenTablero);
}

/// Confirma el movimiento o, con [motivoRechazo], lo rechaza. Sin conexión
/// queda en la bandeja de salida y se envía al volver la red.
Future<ResultadoAccion<Movimiento>> verificarMovimiento(WidgetRef ref, Movimiento m, {String? motivoRechazo}) async {
  final repositorio = ref.read(proveedorRepositorioMovimientos);
  final motivo = motivoRechazo?.trim();
  final resultado = await ejecutarOEncolar(
    ref,
    solicitud: SolicitudPendiente(
      metodo: 'PATCH',
      ruta: '/api/${m.tipo.ruta}/${m.id}/${motivo == null ? 'confirmar' : 'rechazar'}',
      cuerpo: motivo == null ? null : {'motivo': motivo},
      recurso: recursoDeMovimiento(m),
      descripcion: '${motivo == null ? 'Confirmar' : 'Rechazar'} ${m.tipo.etiqueta.toLowerCase()} #${m.id}',
    ),
    enviar: () => motivo == null ? repositorio.confirmar(m.tipo, m.id) : repositorio.rechazar(m.tipo, m.id, motivo),
  );
  if (resultado is AccionAplicada) invalidarTrasVerificar(ref.invalidate);
  return resultado;
}
