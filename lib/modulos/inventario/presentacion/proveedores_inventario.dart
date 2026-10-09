import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../autenticacion/dominio/rol_usuario.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../datos/fuente_remota_inventario.dart';
import '../datos/repositorio_inventario_impl.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';
import '../dominio/repositorio_inventario.dart';

final proveedorRepositorioInventario = Provider<RepositorioInventario>(
  (ref) => RepositorioInventarioImpl(FuenteRemotaInventario(ref.watch(proveedorClienteHttp))),
);

/// Extrae los datos de un [Resultado] o lanza el `Fallo` para que Riverpod
/// lo exponga como `AsyncError` (la interfaz muestra `fallo.mensaje`).
T _datosOLanzar<T>(Resultado<T> resultado) => switch (resultado) {
  Exito(:final datos) => datos,
  Falla(:final fallo) => throw fallo,
};

// ── Lista de insumos ──────────────────────────────────────────────────────
//
// Para recargar se usa `ref.refresh(proveedor.future)`: Riverpod 3 conserva
// los datos anteriores mientras recarga y también si la recarga falla.

final proveedorInsumos = AsyncNotifierProvider<ControladorInsumos, List<Insumo>>(ControladorInsumos.new);

class ControladorInsumos extends AsyncNotifier<List<Insumo>> {
  @override
  Future<List<Insumo>> build() async => _datosOLanzar(await ref.read(proveedorRepositorioInventario).listarInsumos());

  /// Reemplaza un insumo tras modificarlo (p. ej. al ajustar el stock).
  void reemplazar(Insumo actualizado) {
    final actual = state.value;
    if (actual == null) return;
    state = AsyncData([for (final i in actual) i.id == actualizado.id ? actualizado : i]);
  }
}

// ── Predicción de IA de todos los insumos (se carga aparte) ───────────────

/// El backend solo da predicciones a Administrador y Usuario
/// (`/api/prediccion`); Bodega ve el inventario sin el análisis de IA.
final proveedorVeAnalisisIa = Provider<bool>(
  (ref) => switch (ref.watch(proveedorRolActual)) {
    RolUsuario.administrador || RolUsuario.usuario => true,
    _ => false,
  },
);

final proveedorPredicciones = AsyncNotifierProvider<ControladorPredicciones, List<PrediccionInsumo>>(
  ControladorPredicciones.new,
);

class ControladorPredicciones extends AsyncNotifier<List<PrediccionInsumo>> {
  @override
  Future<List<PrediccionInsumo>> build() async {
    if (!ref.watch(proveedorVeAnalisisIa)) return const [];
    return _datosOLanzar(await ref.read(proveedorRepositorioInventario).obtenerPredicciones());
  }
}

/// Nivel de riesgo por id de insumo, derivado de [proveedorPredicciones].
final proveedorRiesgos = Provider<AsyncValue<Map<int, NivelRiesgo>>>(
  (ref) => ref.watch(proveedorPredicciones).whenData((lista) => {for (final p in lista) p.insumoId: p.nivelRiesgo}),
);

// ── Filtros ───────────────────────────────────────────────────────────────

/// Atajos de las tarjetas de resumen.
enum FiltroRapido { todos, stockBajo, sinStock, enRiesgo }

class FiltroInventario {
  const FiltroInventario({this.texto = '', this.rapido = FiltroRapido.todos, this.tipo});

  final String texto;
  final FiltroRapido rapido;

  /// `null` = todos los tipos.
  final String? tipo;

  bool get estaActivo => texto.isNotEmpty || rapido != FiltroRapido.todos || tipo != null;
}

final proveedorFiltroInventario = NotifierProvider<ControladorFiltroInventario, FiltroInventario>(
  ControladorFiltroInventario.new,
);

class ControladorFiltroInventario extends Notifier<FiltroInventario> {
  @override
  FiltroInventario build() => const FiltroInventario();

  void buscar(String texto) => state = FiltroInventario(texto: texto.trim(), rapido: state.rapido, tipo: state.tipo);

  /// Tocar el filtro activo lo quita.
  void alternarRapido(FiltroRapido filtro) => state = FiltroInventario(
    texto: state.texto,
    rapido: state.rapido == filtro ? FiltroRapido.todos : filtro,
    tipo: state.tipo,
  );

  /// Deja solo este filtro (lo usa el Inicio para abrir el inventario filtrado).
  void aplicarSolo(FiltroRapido filtro) => state = FiltroInventario(rapido: filtro);

  void elegirTipo(String? tipo) => state = FiltroInventario(texto: state.texto, rapido: state.rapido, tipo: tipo);

  void limpiar() => state = const FiltroInventario();
}

/// Quita tildes y mayúsculas para buscar "boton" y encontrar "Botón".
String normalizarTexto(String texto) => texto
    .toLowerCase()
    .replaceAll(RegExp('[áà]'), 'a')
    .replaceAll(RegExp('[éè]'), 'e')
    .replaceAll(RegExp('[íì]'), 'i')
    .replaceAll(RegExp('[óò]'), 'o')
    .replaceAll(RegExp('[úùü]'), 'u');

/// Aplica búsqueda, filtro rápido y tipo. Función pura para poder probarla.
List<Insumo> filtrarInsumos(List<Insumo> insumos, FiltroInventario filtro, Map<int, NivelRiesgo> riesgos) {
  final busqueda = normalizarTexto(filtro.texto);
  return [
    for (final insumo in insumos)
      if ((busqueda.isEmpty ||
              normalizarTexto(insumo.nombre).contains(busqueda) ||
              normalizarTexto(insumo.tipo).contains(busqueda)) &&
          (filtro.tipo == null || insumo.tipo == filtro.tipo) &&
          switch (filtro.rapido) {
            FiltroRapido.todos => true,
            FiltroRapido.stockBajo => insumo.estado == EstadoStock.stockBajo,
            FiltroRapido.sinStock => insumo.estado == EstadoStock.sinStock,
            FiltroRapido.enRiesgo => riesgos[insumo.id]?.esPreocupante ?? false,
          })
        insumo,
  ];
}

final proveedorInsumosFiltrados = Provider<AsyncValue<List<Insumo>>>((ref) {
  final insumos = ref.watch(proveedorInsumos);
  final filtro = ref.watch(proveedorFiltroInventario);
  final riesgos = ref.watch(proveedorRiesgos).value ?? const <int, NivelRiesgo>{};
  return insumos.whenData((lista) => filtrarInsumos(lista, filtro, riesgos));
});

/// Tipos de insumo con su cantidad, del más común al menos común.
final proveedorTiposInsumo = Provider<List<(String, int)>>((ref) {
  final insumos = ref.watch(proveedorInsumos).value ?? const [];
  final conteo = <String, int>{};
  for (final insumo in insumos) {
    conteo[insumo.tipo] = (conteo[insumo.tipo] ?? 0) + 1;
  }
  return conteo.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
});

// ── Detalle ───────────────────────────────────────────────────────────────

/// Insumo por id: se toma de la lista si ya está cargada; si no (p. ej. al
/// abrir un enlace directo), se consulta al backend.
final proveedorInsumo = FutureProvider.autoDispose.family<Insumo, int>((ref, id) async {
  final enLista = ref.watch(proveedorInsumos).value?.where((i) => i.id == id).firstOrNull;
  if (enLista != null) return enLista;
  return _datosOLanzar(await ref.read(proveedorRepositorioInventario).obtenerInsumo(id));
});

final proveedorPrediccion = FutureProvider.autoDispose.family<PrediccionInsumo, int>(
  (ref, insumoId) async => _datosOLanzar(await ref.read(proveedorRepositorioInventario).obtenerPrediccion(insumoId)),
);
