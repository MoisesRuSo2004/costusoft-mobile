import 'package:drift/drift.dart';

import 'base_datos_local.dart';

/// Respuesta guardada y cuándo se obtuvo del servidor.
class RespuestaGuardada {
  const RespuestaGuardada({required this.cuerpo, required this.guardadaEn});

  final String cuerpo;
  final DateTime guardadaEn;
}

/// Copia local de las consultas: se escribe con cada respuesta del servidor y
/// se lee cuando no hay conexión.
abstract interface class CopiaLocal {
  Future<void> guardar(String clave, String cuerpo);

  Future<RespuestaGuardada?> leer(String clave);

  /// Id del usuario dueño de la copia; al entrar otro usuario se borra.
  Future<int?> leerDueno();

  Future<void> asignarDueno(int usuarioId);

  /// Quita las copias viejas y deja como máximo [maximo] (las más recientes).
  Future<void> podar({Duration antiguedad = const Duration(days: 14), int maximo = 400});

  Future<void> limpiar();
}

class CopiaLocalDrift implements CopiaLocal {
  const CopiaLocalDrift(this._bd);

  final BaseDatosLocal _bd;

  static const _claveDueno = '__dueno';

  @override
  Future<void> guardar(String clave, String cuerpo) => _bd
      .into(_bd.respuestasGuardadas)
      .insertOnConflictUpdate(
        RespuestasGuardadasCompanion.insert(clave: clave, cuerpo: cuerpo, guardadaEn: DateTime.now()),
      );

  @override
  Future<RespuestaGuardada?> leer(String clave) async {
    final fila = await (_bd.select(_bd.respuestasGuardadas)..where((t) => t.clave.equals(clave))).getSingleOrNull();
    return fila == null ? null : RespuestaGuardada(cuerpo: fila.cuerpo, guardadaEn: fila.guardadaEn);
  }

  @override
  Future<int?> leerDueno() async => int.tryParse((await leer(_claveDueno))?.cuerpo ?? '');

  @override
  Future<void> asignarDueno(int usuarioId) => guardar(_claveDueno, '$usuarioId');

  @override
  Future<void> podar({Duration antiguedad = const Duration(days: 14), int maximo = 400}) async {
    final t = _bd.respuestasGuardadas;
    await (_bd.delete(t)..where(
          (f) =>
              f.guardadaEn.isSmallerThanValue(DateTime.now().subtract(antiguedad)) & f.clave.equals(_claveDueno).not(),
        ))
        .go();
    final sobrantes =
        await (_bd.selectOnly(t)
              ..addColumns([t.clave])
              ..orderBy([OrderingTerm.desc(t.guardadaEn)])
              ..limit(1000, offset: maximo))
            .map((f) => f.read(t.clave)!)
            .get();
    if (sobrantes.isNotEmpty) await (_bd.delete(t)..where((f) => f.clave.isIn(sobrantes))).go();
  }

  @override
  Future<void> limpiar() => _bd.delete(_bd.respuestasGuardadas).go();
}
