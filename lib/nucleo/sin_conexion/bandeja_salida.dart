import 'dart:convert';

import 'package:drift/drift.dart';

import 'base_datos_local.dart';

/// Cambio que se quiere hacer en el servidor y que, sin conexión, espera en
/// la bandeja de salida.
class SolicitudPendiente {
  const SolicitudPendiente({
    required this.metodo,
    required this.ruta,
    required this.recurso,
    required this.descripcion,
    this.cuerpo,
  });

  final String metodo;
  final String ruta;
  final Map<String, dynamic>? cuerpo;

  /// Recurso afectado (p. ej. `entradas/12`): la interfaz lo marca como
  /// "por enviar" y evita que se repita la acción.
  final String recurso;

  /// Texto para el usuario, p. ej. "Confirmar entrada #12".
  final String descripcion;
}

enum EstadoAccion { pendiente, conflicto }

class AccionPendiente {
  const AccionPendiente({
    required this.id,
    required this.solicitud,
    required this.estado,
    required this.intentos,
    required this.creadaEn,
    this.ultimoError,
  });

  final int id;
  final SolicitudPendiente solicitud;
  final EstadoAccion estado;
  final int intentos;
  final DateTime creadaEn;

  /// Mensaje del servidor si la rechazó, o del último intento fallido.
  final String? ultimoError;
}

/// Cola FIFO de cambios hechos sin conexión.
abstract interface class BandejaSalida {
  /// Todas las acciones (pendientes y en conflicto), de la más antigua a la
  /// más reciente; emite de nuevo con cada cambio.
  Stream<List<AccionPendiente>> observar();

  Future<List<AccionPendiente>> listarPendientes();

  Future<void> agregar(SolicitudPendiente solicitud);

  Future<void> eliminar(int id);

  /// El servidor la rechazó (p. ej. otra persona ya la había procesado).
  Future<void> marcarConflicto(int id, String mensaje);

  /// Falló por algo pasajero (red, servidor caído): se reintentará.
  Future<void> registrarIntento(int id, String mensaje);

  Future<void> limpiar();
}

class BandejaSalidaDrift implements BandejaSalida {
  const BandejaSalidaDrift(this._bd);

  final BaseDatosLocal _bd;

  AccionPendiente _aEntidad(FilaAccion f) => AccionPendiente(
    id: f.id,
    solicitud: SolicitudPendiente(
      metodo: f.metodo,
      ruta: f.ruta,
      cuerpo: f.cuerpo == null ? null : jsonDecode(f.cuerpo!) as Map<String, dynamic>,
      recurso: f.recurso,
      descripcion: f.descripcion,
    ),
    estado: f.estado == 'conflicto' ? EstadoAccion.conflicto : EstadoAccion.pendiente,
    intentos: f.intentos,
    creadaEn: f.creadaEn,
    ultimoError: f.ultimoError,
  );

  SimpleSelectStatement<$AccionesPendientesTable, FilaAccion> _todas() =>
      _bd.select(_bd.accionesPendientes)..orderBy([(t) => OrderingTerm.asc(t.id)]);

  @override
  Stream<List<AccionPendiente>> observar() => _todas().watch().map((filas) => filas.map(_aEntidad).toList());

  @override
  Future<List<AccionPendiente>> listarPendientes() async =>
      (await (_todas()..where((t) => t.estado.equals('pendiente'))).get()).map(_aEntidad).toList();

  @override
  Future<void> agregar(SolicitudPendiente s) => _bd
      .into(_bd.accionesPendientes)
      .insert(
        AccionesPendientesCompanion.insert(
          metodo: s.metodo,
          ruta: s.ruta,
          cuerpo: Value(s.cuerpo == null ? null : jsonEncode(s.cuerpo)),
          recurso: s.recurso,
          descripcion: s.descripcion,
          creadaEn: DateTime.now(),
        ),
      );

  @override
  Future<void> eliminar(int id) => (_bd.delete(_bd.accionesPendientes)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> marcarConflicto(int id, String mensaje) =>
      (_bd.update(_bd.accionesPendientes)..where((t) => t.id.equals(id))).write(
        AccionesPendientesCompanion(estado: const Value('conflicto'), ultimoError: Value(mensaje)),
      );

  @override
  Future<void> registrarIntento(int id, String mensaje) => _bd.customUpdate(
    'UPDATE acciones_pendientes SET intentos = intentos + 1, ultimo_error = ? WHERE id = ?',
    variables: [Variable.withString(mensaje), Variable.withInt(id)],
    updates: {_bd.accionesPendientes},
  );

  @override
  Future<void> limpiar() => _bd.delete(_bd.accionesPendientes).go();
}
