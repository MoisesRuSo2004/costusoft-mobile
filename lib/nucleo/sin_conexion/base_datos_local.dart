import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'base_datos_local.g.dart';

/// Última respuesta de cada consulta GET, para mostrarla sin conexión.
@DataClassName('FilaRespuesta')
class RespuestasGuardadas extends Table {
  /// Método + URL completa con sus parámetros.
  TextColumn get clave => text()();

  /// Cuerpo JSON tal como lo devolvió el backend.
  TextColumn get cuerpo => text()();
  DateTimeColumn get guardadaEn => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {clave};
}

/// Bandeja de salida: cambios hechos sin conexión, en orden de llegada.
@DataClassName('FilaAccion')
class AccionesPendientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get metodo => text()();
  TextColumn get ruta => text()();

  /// Cuerpo JSON de la petición (`null` si no lleva).
  TextColumn get cuerpo => text().nullable()();

  /// Recurso afectado, p. ej. `entradas/12` o `pedidos/9440`.
  TextColumn get recurso => text()();
  TextColumn get descripcion => text()();

  /// `pendiente` o `conflicto` (el servidor la rechazó).
  TextColumn get estado => text().withDefault(const Constant('pendiente'))();
  IntColumn get intentos => integer().withDefault(const Constant(0))();
  TextColumn get ultimoError => text().nullable()();
  DateTimeColumn get creadaEn => dateTime()();
}

/// Base SQLite del dispositivo. En web usa WebAssembly (`web/sqlite3.wasm` y
/// `web/drift_worker.js`) y guarda en OPFS o IndexedDB según el navegador.
@DriftDatabase(tables: [RespuestasGuardadas, AccionesPendientes])
class BaseDatosLocal extends _$BaseDatosLocal {
  BaseDatosLocal([QueryExecutor? ejecutor]) : super(ejecutor ?? _abrir());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrir() => driftDatabase(
    name: 'costusoft',
    web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
  );
}
