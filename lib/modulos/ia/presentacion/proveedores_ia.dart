import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../autenticacion/dominio/estado_sesion.dart';
import '../../autenticacion/dominio/rol_usuario.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../datos/fuente_remota_ia.dart';
import '../datos/repositorios_ia_impl.dart';
import '../dominio/entidades_ia.dart';
import '../dominio/repositorio_ia.dart';

final _proveedorFuenteIa = Provider<FuenteRemotaIa>((ref) {
  final esInstitucion = ref.watch(proveedorRolActual) == RolUsuario.institucion;
  return FuenteRemotaIa(
    ref.watch(proveedorClienteHttp),
    rutaChat: esInstitucion ? '/api/institucion/ia/chat' : '/api/ia/chat',
  );
});

final proveedorRepositorioIa = Provider<RepositorioIa>((ref) => RepositorioIaImpl(ref.watch(_proveedorFuenteIa)));

final proveedorRepositorioOptimizacion = Provider<RepositorioOptimizacion>(
  (ref) => RepositorioOptimizacionImpl(ref.watch(_proveedorFuenteIa)),
);

T _datosOLanzar<T>(Resultado<T> resultado) => switch (resultado) {
  Exito(:final datos) => datos,
  Falla(:final fallo) => throw fallo,
};

// ── Resumen del día ───────────────────────────────────────────────────────

/// `null` hasta que el usuario lo pide (cada resumen consume tokens del LLM).
final proveedorResumenDelDia = NotifierProvider<ControladorResumenDelDia, AsyncValue<RespuestaIa>?>(
  ControladorResumenDelDia.new,
);

class ControladorResumenDelDia extends Notifier<AsyncValue<RespuestaIa>?> {
  @override
  AsyncValue<RespuestaIa>? build() => null;

  Future<void> generar() async {
    state = const AsyncLoading();
    final resultado = await ref.read(proveedorRepositorioIa).obtenerResumenDelDia();
    state = switch (resultado) {
      Exito(:final datos) => AsyncData(datos),
      Falla(:final fallo) => AsyncError(fallo, StackTrace.current),
    };
  }
}

// ── Conversación con el asistente ─────────────────────────────────────────

final proveedorChat = NotifierProvider<ControladorChat, List<MensajeChat>>(ControladorChat.new);

/// Conversación de la sesión actual (se pierde al cerrar la app).
class ControladorChat extends Notifier<List<MensajeChat>> {
  int _siguienteId = 0;

  @override
  List<MensajeChat> build() {
    // La conversación es de quien la escribió: se reinicia al cambiar de usuario.
    ref.watch(proveedorSesion.select((s) => s is SesionActiva ? s.usuario.id : null));
    return const [];
  }

  bool get estaRespondiendo => state.any((m) => m.esperando);

  Future<void> preguntar(String pregunta) =>
      _enviar(textoUsuario: pregunta.trim(), llamada: () => ref.read(proveedorRepositorioIa).preguntar(pregunta));

  Future<void> consultar(TipoConsultaIa tipo) => _enviar(
    textoUsuario: tipo.descripcion,
    titulo: tipo.etiqueta,
    llamada: () => ref.read(proveedorRepositorioIa).consultar(tipo),
  );

  Future<void> generarOrdenCompra() => _enviar(
    textoUsuario: 'Genera una orden de compra con los insumos en stock bajo',
    titulo: 'Orden de compra',
    llamada: () => ref.read(proveedorRepositorioIa).generarOrdenCompra(),
  );

  Future<void> _enviar({
    required String textoUsuario,
    required Future<Resultado<RespuestaIa>> Function() llamada,
    String? titulo,
  }) async {
    if (textoUsuario.isEmpty || estaRespondiendo) return;
    final idRespuesta = _siguienteId + 1;
    state = [
      ...state,
      MensajeChat(id: _siguienteId, autor: AutorMensaje.usuario, texto: textoUsuario),
      MensajeChat(id: idRespuesta, autor: AutorMensaje.asistente, texto: '', titulo: titulo, esperando: true),
    ];
    _siguienteId += 2;

    final resultado = await llamada();
    final respuesta = switch (resultado) {
      Exito(:final datos) => MensajeChat(
        id: idRespuesta,
        autor: AutorMensaje.asistente,
        texto: datos.texto,
        titulo: titulo,
        respuesta: datos,
      ),
      Falla(:final fallo) => MensajeChat(
        id: idRespuesta,
        autor: AutorMensaje.asistente,
        texto: '',
        titulo: titulo,
        error: fallo.mensaje,
      ),
    };
    state = [for (final m in state) m.id == idRespuesta ? respuesta : m];
  }

  void limpiar() => state = const [];
}

// ── Producción óptima (ILP) ──────────────────────────────────────────────

final proveedorColegios = FutureProvider<List<Colegio>>(
  (ref) async => _datosOLanzar(await ref.read(proveedorRepositorioOptimizacion).listarColegios()),
);

final proveedorHistorialOptimizacion = FutureProvider.autoDispose<List<PlanProduccion>>(
  (ref) async => _datosOLanzar(await ref.read(proveedorRepositorioOptimizacion).historial()),
);

/// Último plan calculado en esta sesión (`null` si aún no se calcula).
final proveedorPlanCalculado = NotifierProvider<ControladorPlan, AsyncValue<PlanProduccion>?>(ControladorPlan.new);

class ControladorPlan extends Notifier<AsyncValue<PlanProduccion>?> {
  @override
  AsyncValue<PlanProduccion>? build() => null;

  Future<void> calcular({required int colegioId, required bool incluirDemanda}) async {
    state = const AsyncLoading();
    final resultado = await ref
        .read(proveedorRepositorioOptimizacion)
        .optimizar(colegioId: colegioId, incluirDemanda: incluirDemanda);
    state = switch (resultado) {
      Exito(:final datos) => AsyncData(datos),
      Falla(:final fallo) => AsyncError<PlanProduccion>(fallo, StackTrace.current),
    };
    // La nueva ejecución quedó guardada en el historial.
    if (resultado.esExito) ref.invalidate(proveedorHistorialOptimizacion);
  }
}

/// Mensaje legible de un error de [AsyncValue].
String mensajeDeError(Object error) => error is Fallo ? error.mensaje : 'Ocurrió un error inesperado.';
