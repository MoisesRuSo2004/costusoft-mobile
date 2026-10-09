// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_datos_local.dart';

// ignore_for_file: type=lint
class $RespuestasGuardadasTable extends RespuestasGuardadas with TableInfo<$RespuestasGuardadasTable, FilaRespuesta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RespuestasGuardadasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuerpoMeta = const VerificationMeta('cuerpo');
  @override
  late final GeneratedColumn<String> cuerpo = GeneratedColumn<String>(
    'cuerpo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guardadaEnMeta = const VerificationMeta('guardadaEn');
  @override
  late final GeneratedColumn<DateTime> guardadaEn = GeneratedColumn<DateTime>(
    'guardada_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, cuerpo, guardadaEn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'respuestas_guardadas';
  @override
  VerificationContext validateIntegrity(Insertable<FilaRespuesta> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(_claveMeta, clave.isAcceptableOrUnknown(data['clave']!, _claveMeta));
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('cuerpo')) {
      context.handle(_cuerpoMeta, cuerpo.isAcceptableOrUnknown(data['cuerpo']!, _cuerpoMeta));
    } else if (isInserting) {
      context.missing(_cuerpoMeta);
    }
    if (data.containsKey('guardada_en')) {
      context.handle(_guardadaEnMeta, guardadaEn.isAcceptableOrUnknown(data['guardada_en']!, _guardadaEnMeta));
    } else if (isInserting) {
      context.missing(_guardadaEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  FilaRespuesta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaRespuesta(
      clave: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}clave'])!,
      cuerpo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cuerpo'])!,
      guardadaEn: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}guardada_en'])!,
    );
  }

  @override
  $RespuestasGuardadasTable createAlias(String alias) {
    return $RespuestasGuardadasTable(attachedDatabase, alias);
  }
}

class FilaRespuesta extends DataClass implements Insertable<FilaRespuesta> {
  /// Método + URL completa con sus parámetros.
  final String clave;

  /// Cuerpo JSON tal como lo devolvió el backend.
  final String cuerpo;
  final DateTime guardadaEn;
  const FilaRespuesta({required this.clave, required this.cuerpo, required this.guardadaEn});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['cuerpo'] = Variable<String>(cuerpo);
    map['guardada_en'] = Variable<DateTime>(guardadaEn);
    return map;
  }

  RespuestasGuardadasCompanion toCompanion(bool nullToAbsent) {
    return RespuestasGuardadasCompanion(clave: Value(clave), cuerpo: Value(cuerpo), guardadaEn: Value(guardadaEn));
  }

  factory FilaRespuesta.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaRespuesta(
      clave: serializer.fromJson<String>(json['clave']),
      cuerpo: serializer.fromJson<String>(json['cuerpo']),
      guardadaEn: serializer.fromJson<DateTime>(json['guardadaEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'cuerpo': serializer.toJson<String>(cuerpo),
      'guardadaEn': serializer.toJson<DateTime>(guardadaEn),
    };
  }

  FilaRespuesta copyWith({String? clave, String? cuerpo, DateTime? guardadaEn}) => FilaRespuesta(
    clave: clave ?? this.clave,
    cuerpo: cuerpo ?? this.cuerpo,
    guardadaEn: guardadaEn ?? this.guardadaEn,
  );
  FilaRespuesta copyWithCompanion(RespuestasGuardadasCompanion data) {
    return FilaRespuesta(
      clave: data.clave.present ? data.clave.value : this.clave,
      cuerpo: data.cuerpo.present ? data.cuerpo.value : this.cuerpo,
      guardadaEn: data.guardadaEn.present ? data.guardadaEn.value : this.guardadaEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaRespuesta(')
          ..write('clave: $clave, ')
          ..write('cuerpo: $cuerpo, ')
          ..write('guardadaEn: $guardadaEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, cuerpo, guardadaEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaRespuesta &&
          other.clave == this.clave &&
          other.cuerpo == this.cuerpo &&
          other.guardadaEn == this.guardadaEn);
}

class RespuestasGuardadasCompanion extends UpdateCompanion<FilaRespuesta> {
  final Value<String> clave;
  final Value<String> cuerpo;
  final Value<DateTime> guardadaEn;
  final Value<int> rowid;
  const RespuestasGuardadasCompanion({
    this.clave = const Value.absent(),
    this.cuerpo = const Value.absent(),
    this.guardadaEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RespuestasGuardadasCompanion.insert({
    required String clave,
    required String cuerpo,
    required DateTime guardadaEn,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       cuerpo = Value(cuerpo),
       guardadaEn = Value(guardadaEn);
  static Insertable<FilaRespuesta> custom({
    Expression<String>? clave,
    Expression<String>? cuerpo,
    Expression<DateTime>? guardadaEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (cuerpo != null) 'cuerpo': cuerpo,
      if (guardadaEn != null) 'guardada_en': guardadaEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RespuestasGuardadasCompanion copyWith({
    Value<String>? clave,
    Value<String>? cuerpo,
    Value<DateTime>? guardadaEn,
    Value<int>? rowid,
  }) {
    return RespuestasGuardadasCompanion(
      clave: clave ?? this.clave,
      cuerpo: cuerpo ?? this.cuerpo,
      guardadaEn: guardadaEn ?? this.guardadaEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (cuerpo.present) {
      map['cuerpo'] = Variable<String>(cuerpo.value);
    }
    if (guardadaEn.present) {
      map['guardada_en'] = Variable<DateTime>(guardadaEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RespuestasGuardadasCompanion(')
          ..write('clave: $clave, ')
          ..write('cuerpo: $cuerpo, ')
          ..write('guardadaEn: $guardadaEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccionesPendientesTable extends AccionesPendientes with TableInfo<$AccionesPendientesTable, FilaAccion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccionesPendientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _metodoMeta = const VerificationMeta('metodo');
  @override
  late final GeneratedColumn<String> metodo = GeneratedColumn<String>(
    'metodo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rutaMeta = const VerificationMeta('ruta');
  @override
  late final GeneratedColumn<String> ruta = GeneratedColumn<String>(
    'ruta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuerpoMeta = const VerificationMeta('cuerpo');
  @override
  late final GeneratedColumn<String> cuerpo = GeneratedColumn<String>(
    'cuerpo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recursoMeta = const VerificationMeta('recurso');
  @override
  late final GeneratedColumn<String> recurso = GeneratedColumn<String>(
    'recurso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta('descripcion');
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendiente'),
  );
  static const VerificationMeta _intentosMeta = const VerificationMeta('intentos');
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta('ultimoError');
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadaEnMeta = const VerificationMeta('creadaEn');
  @override
  late final GeneratedColumn<DateTime> creadaEn = GeneratedColumn<DateTime>(
    'creada_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    metodo,
    ruta,
    cuerpo,
    recurso,
    descripcion,
    estado,
    intentos,
    ultimoError,
    creadaEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'acciones_pendientes';
  @override
  VerificationContext validateIntegrity(Insertable<FilaAccion> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('metodo')) {
      context.handle(_metodoMeta, metodo.isAcceptableOrUnknown(data['metodo']!, _metodoMeta));
    } else if (isInserting) {
      context.missing(_metodoMeta);
    }
    if (data.containsKey('ruta')) {
      context.handle(_rutaMeta, ruta.isAcceptableOrUnknown(data['ruta']!, _rutaMeta));
    } else if (isInserting) {
      context.missing(_rutaMeta);
    }
    if (data.containsKey('cuerpo')) {
      context.handle(_cuerpoMeta, cuerpo.isAcceptableOrUnknown(data['cuerpo']!, _cuerpoMeta));
    }
    if (data.containsKey('recurso')) {
      context.handle(_recursoMeta, recurso.isAcceptableOrUnknown(data['recurso']!, _recursoMeta));
    } else if (isInserting) {
      context.missing(_recursoMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(_descripcionMeta, descripcion.isAcceptableOrUnknown(data['descripcion']!, _descripcionMeta));
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(_estadoMeta, estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta));
    }
    if (data.containsKey('intentos')) {
      context.handle(_intentosMeta, intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta));
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(_ultimoErrorMeta, ultimoError.isAcceptableOrUnknown(data['ultimo_error']!, _ultimoErrorMeta));
    }
    if (data.containsKey('creada_en')) {
      context.handle(_creadaEnMeta, creadaEn.isAcceptableOrUnknown(data['creada_en']!, _creadaEnMeta));
    } else if (isInserting) {
      context.missing(_creadaEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaAccion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaAccion(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      metodo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}metodo'])!,
      ruta: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}ruta'])!,
      cuerpo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cuerpo']),
      recurso: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}recurso'])!,
      descripcion: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}descripcion'])!,
      estado: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}estado'])!,
      intentos: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}intentos'])!,
      ultimoError: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}ultimo_error']),
      creadaEn: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}creada_en'])!,
    );
  }

  @override
  $AccionesPendientesTable createAlias(String alias) {
    return $AccionesPendientesTable(attachedDatabase, alias);
  }
}

class FilaAccion extends DataClass implements Insertable<FilaAccion> {
  final int id;
  final String metodo;
  final String ruta;

  /// Cuerpo JSON de la petición (`null` si no lleva).
  final String? cuerpo;

  /// Recurso afectado, p. ej. `entradas/12` o `pedidos/9440`.
  final String recurso;
  final String descripcion;

  /// `pendiente` o `conflicto` (el servidor la rechazó).
  final String estado;
  final int intentos;
  final String? ultimoError;
  final DateTime creadaEn;
  const FilaAccion({
    required this.id,
    required this.metodo,
    required this.ruta,
    this.cuerpo,
    required this.recurso,
    required this.descripcion,
    required this.estado,
    required this.intentos,
    this.ultimoError,
    required this.creadaEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['metodo'] = Variable<String>(metodo);
    map['ruta'] = Variable<String>(ruta);
    if (!nullToAbsent || cuerpo != null) {
      map['cuerpo'] = Variable<String>(cuerpo);
    }
    map['recurso'] = Variable<String>(recurso);
    map['descripcion'] = Variable<String>(descripcion);
    map['estado'] = Variable<String>(estado);
    map['intentos'] = Variable<int>(intentos);
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    map['creada_en'] = Variable<DateTime>(creadaEn);
    return map;
  }

  AccionesPendientesCompanion toCompanion(bool nullToAbsent) {
    return AccionesPendientesCompanion(
      id: Value(id),
      metodo: Value(metodo),
      ruta: Value(ruta),
      cuerpo: cuerpo == null && nullToAbsent ? const Value.absent() : Value(cuerpo),
      recurso: Value(recurso),
      descripcion: Value(descripcion),
      estado: Value(estado),
      intentos: Value(intentos),
      ultimoError: ultimoError == null && nullToAbsent ? const Value.absent() : Value(ultimoError),
      creadaEn: Value(creadaEn),
    );
  }

  factory FilaAccion.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaAccion(
      id: serializer.fromJson<int>(json['id']),
      metodo: serializer.fromJson<String>(json['metodo']),
      ruta: serializer.fromJson<String>(json['ruta']),
      cuerpo: serializer.fromJson<String?>(json['cuerpo']),
      recurso: serializer.fromJson<String>(json['recurso']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      estado: serializer.fromJson<String>(json['estado']),
      intentos: serializer.fromJson<int>(json['intentos']),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
      creadaEn: serializer.fromJson<DateTime>(json['creadaEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'metodo': serializer.toJson<String>(metodo),
      'ruta': serializer.toJson<String>(ruta),
      'cuerpo': serializer.toJson<String?>(cuerpo),
      'recurso': serializer.toJson<String>(recurso),
      'descripcion': serializer.toJson<String>(descripcion),
      'estado': serializer.toJson<String>(estado),
      'intentos': serializer.toJson<int>(intentos),
      'ultimoError': serializer.toJson<String?>(ultimoError),
      'creadaEn': serializer.toJson<DateTime>(creadaEn),
    };
  }

  FilaAccion copyWith({
    int? id,
    String? metodo,
    String? ruta,
    Value<String?> cuerpo = const Value.absent(),
    String? recurso,
    String? descripcion,
    String? estado,
    int? intentos,
    Value<String?> ultimoError = const Value.absent(),
    DateTime? creadaEn,
  }) => FilaAccion(
    id: id ?? this.id,
    metodo: metodo ?? this.metodo,
    ruta: ruta ?? this.ruta,
    cuerpo: cuerpo.present ? cuerpo.value : this.cuerpo,
    recurso: recurso ?? this.recurso,
    descripcion: descripcion ?? this.descripcion,
    estado: estado ?? this.estado,
    intentos: intentos ?? this.intentos,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
    creadaEn: creadaEn ?? this.creadaEn,
  );
  FilaAccion copyWithCompanion(AccionesPendientesCompanion data) {
    return FilaAccion(
      id: data.id.present ? data.id.value : this.id,
      metodo: data.metodo.present ? data.metodo.value : this.metodo,
      ruta: data.ruta.present ? data.ruta.value : this.ruta,
      cuerpo: data.cuerpo.present ? data.cuerpo.value : this.cuerpo,
      recurso: data.recurso.present ? data.recurso.value : this.recurso,
      descripcion: data.descripcion.present ? data.descripcion.value : this.descripcion,
      estado: data.estado.present ? data.estado.value : this.estado,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
      ultimoError: data.ultimoError.present ? data.ultimoError.value : this.ultimoError,
      creadaEn: data.creadaEn.present ? data.creadaEn.value : this.creadaEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaAccion(')
          ..write('id: $id, ')
          ..write('metodo: $metodo, ')
          ..write('ruta: $ruta, ')
          ..write('cuerpo: $cuerpo, ')
          ..write('recurso: $recurso, ')
          ..write('descripcion: $descripcion, ')
          ..write('estado: $estado, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('creadaEn: $creadaEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, metodo, ruta, cuerpo, recurso, descripcion, estado, intentos, ultimoError, creadaEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaAccion &&
          other.id == this.id &&
          other.metodo == this.metodo &&
          other.ruta == this.ruta &&
          other.cuerpo == this.cuerpo &&
          other.recurso == this.recurso &&
          other.descripcion == this.descripcion &&
          other.estado == this.estado &&
          other.intentos == this.intentos &&
          other.ultimoError == this.ultimoError &&
          other.creadaEn == this.creadaEn);
}

class AccionesPendientesCompanion extends UpdateCompanion<FilaAccion> {
  final Value<int> id;
  final Value<String> metodo;
  final Value<String> ruta;
  final Value<String?> cuerpo;
  final Value<String> recurso;
  final Value<String> descripcion;
  final Value<String> estado;
  final Value<int> intentos;
  final Value<String?> ultimoError;
  final Value<DateTime> creadaEn;
  const AccionesPendientesCompanion({
    this.id = const Value.absent(),
    this.metodo = const Value.absent(),
    this.ruta = const Value.absent(),
    this.cuerpo = const Value.absent(),
    this.recurso = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.estado = const Value.absent(),
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.creadaEn = const Value.absent(),
  });
  AccionesPendientesCompanion.insert({
    this.id = const Value.absent(),
    required String metodo,
    required String ruta,
    this.cuerpo = const Value.absent(),
    required String recurso,
    required String descripcion,
    this.estado = const Value.absent(),
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    required DateTime creadaEn,
  }) : metodo = Value(metodo),
       ruta = Value(ruta),
       recurso = Value(recurso),
       descripcion = Value(descripcion),
       creadaEn = Value(creadaEn);
  static Insertable<FilaAccion> custom({
    Expression<int>? id,
    Expression<String>? metodo,
    Expression<String>? ruta,
    Expression<String>? cuerpo,
    Expression<String>? recurso,
    Expression<String>? descripcion,
    Expression<String>? estado,
    Expression<int>? intentos,
    Expression<String>? ultimoError,
    Expression<DateTime>? creadaEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metodo != null) 'metodo': metodo,
      if (ruta != null) 'ruta': ruta,
      if (cuerpo != null) 'cuerpo': cuerpo,
      if (recurso != null) 'recurso': recurso,
      if (descripcion != null) 'descripcion': descripcion,
      if (estado != null) 'estado': estado,
      if (intentos != null) 'intentos': intentos,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (creadaEn != null) 'creada_en': creadaEn,
    });
  }

  AccionesPendientesCompanion copyWith({
    Value<int>? id,
    Value<String>? metodo,
    Value<String>? ruta,
    Value<String?>? cuerpo,
    Value<String>? recurso,
    Value<String>? descripcion,
    Value<String>? estado,
    Value<int>? intentos,
    Value<String?>? ultimoError,
    Value<DateTime>? creadaEn,
  }) {
    return AccionesPendientesCompanion(
      id: id ?? this.id,
      metodo: metodo ?? this.metodo,
      ruta: ruta ?? this.ruta,
      cuerpo: cuerpo ?? this.cuerpo,
      recurso: recurso ?? this.recurso,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
      creadaEn: creadaEn ?? this.creadaEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (metodo.present) {
      map['metodo'] = Variable<String>(metodo.value);
    }
    if (ruta.present) {
      map['ruta'] = Variable<String>(ruta.value);
    }
    if (cuerpo.present) {
      map['cuerpo'] = Variable<String>(cuerpo.value);
    }
    if (recurso.present) {
      map['recurso'] = Variable<String>(recurso.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (creadaEn.present) {
      map['creada_en'] = Variable<DateTime>(creadaEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccionesPendientesCompanion(')
          ..write('id: $id, ')
          ..write('metodo: $metodo, ')
          ..write('ruta: $ruta, ')
          ..write('cuerpo: $cuerpo, ')
          ..write('recurso: $recurso, ')
          ..write('descripcion: $descripcion, ')
          ..write('estado: $estado, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('creadaEn: $creadaEn')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseDatosLocal extends GeneratedDatabase {
  _$BaseDatosLocal(QueryExecutor e) : super(e);
  $BaseDatosLocalManager get managers => $BaseDatosLocalManager(this);
  late final $RespuestasGuardadasTable respuestasGuardadas = $RespuestasGuardadasTable(this);
  late final $AccionesPendientesTable accionesPendientes = $AccionesPendientesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [respuestasGuardadas, accionesPendientes];
}

typedef $$RespuestasGuardadasTableCreateCompanionBuilder = RespuestasGuardadasCompanion Function({
  required String clave,
  required String cuerpo,
  required DateTime guardadaEn,
  Value<int> rowid,
});
typedef $$RespuestasGuardadasTableUpdateCompanionBuilder = RespuestasGuardadasCompanion Function({
  Value<String> clave,
  Value<String> cuerpo,
  Value<DateTime> guardadaEn,
  Value<int> rowid,
});

class $$RespuestasGuardadasTableFilterComposer extends Composer<_$BaseDatosLocal, $RespuestasGuardadasTable> {
  $$RespuestasGuardadasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cuerpo =>
      $composableBuilder(column: $table.cuerpo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get guardadaEn =>
      $composableBuilder(column: $table.guardadaEn, builder: (column) => ColumnFilters(column));
}

class $$RespuestasGuardadasTableOrderingComposer extends Composer<_$BaseDatosLocal, $RespuestasGuardadasTable> {
  $$RespuestasGuardadasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cuerpo =>
      $composableBuilder(column: $table.cuerpo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get guardadaEn =>
      $composableBuilder(column: $table.guardadaEn, builder: (column) => ColumnOrderings(column));
}

class $$RespuestasGuardadasTableAnnotationComposer extends Composer<_$BaseDatosLocal, $RespuestasGuardadasTable> {
  $$RespuestasGuardadasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave => $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get cuerpo => $composableBuilder(column: $table.cuerpo, builder: (column) => column);

  GeneratedColumn<DateTime> get guardadaEn =>
      $composableBuilder(column: $table.guardadaEn, builder: (column) => column);
}

class $$RespuestasGuardadasTableTableManager
    extends
        RootTableManager<
          _$BaseDatosLocal,
          $RespuestasGuardadasTable,
          FilaRespuesta,
          $$RespuestasGuardadasTableFilterComposer,
          $$RespuestasGuardadasTableOrderingComposer,
          $$RespuestasGuardadasTableAnnotationComposer,
          $$RespuestasGuardadasTableCreateCompanionBuilder,
          $$RespuestasGuardadasTableUpdateCompanionBuilder,
          (FilaRespuesta, BaseReferences<_$BaseDatosLocal, $RespuestasGuardadasTable, FilaRespuesta>),
          FilaRespuesta,
          PrefetchHooks Function()
        > {
  $$RespuestasGuardadasTableTableManager(_$BaseDatosLocal db, $RespuestasGuardadasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RespuestasGuardadasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RespuestasGuardadasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RespuestasGuardadasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> clave = const Value.absent(),
            Value<String> cuerpo = const Value.absent(),
            Value<DateTime> guardadaEn = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => RespuestasGuardadasCompanion(clave: clave, cuerpo: cuerpo, guardadaEn: guardadaEn, rowid: rowid),
          createCompanionCallback: ({
            required String clave,
            required String cuerpo,
            required DateTime guardadaEn,
            Value<int> rowid = const Value.absent(),
          }) => RespuestasGuardadasCompanion.insert(clave: clave, cuerpo: cuerpo, guardadaEn: guardadaEn, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RespuestasGuardadasTable, FilaRespuesta>(table),
                  BaseReferences<_$BaseDatosLocal, $RespuestasGuardadasTable, FilaRespuesta>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RespuestasGuardadasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDatosLocal,
      $RespuestasGuardadasTable,
      FilaRespuesta,
      $$RespuestasGuardadasTableFilterComposer,
      $$RespuestasGuardadasTableOrderingComposer,
      $$RespuestasGuardadasTableAnnotationComposer,
      $$RespuestasGuardadasTableCreateCompanionBuilder,
      $$RespuestasGuardadasTableUpdateCompanionBuilder,
      (FilaRespuesta, BaseReferences<_$BaseDatosLocal, $RespuestasGuardadasTable, FilaRespuesta>),
      FilaRespuesta,
      PrefetchHooks Function()
    >;
typedef $$AccionesPendientesTableCreateCompanionBuilder = AccionesPendientesCompanion Function({
  Value<int> id,
  required String metodo,
  required String ruta,
  Value<String?> cuerpo,
  required String recurso,
  required String descripcion,
  Value<String> estado,
  Value<int> intentos,
  Value<String?> ultimoError,
  required DateTime creadaEn,
});
typedef $$AccionesPendientesTableUpdateCompanionBuilder = AccionesPendientesCompanion Function({
  Value<int> id,
  Value<String> metodo,
  Value<String> ruta,
  Value<String?> cuerpo,
  Value<String> recurso,
  Value<String> descripcion,
  Value<String> estado,
  Value<int> intentos,
  Value<String?> ultimoError,
  Value<DateTime> creadaEn,
});

class $$AccionesPendientesTableFilterComposer extends Composer<_$BaseDatosLocal, $AccionesPendientesTable> {
  $$AccionesPendientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metodo =>
      $composableBuilder(column: $table.metodo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ruta => $composableBuilder(column: $table.ruta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cuerpo =>
      $composableBuilder(column: $table.cuerpo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurso =>
      $composableBuilder(column: $table.recurso, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descripcion =>
      $composableBuilder(column: $table.descripcion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ultimoError =>
      $composableBuilder(column: $table.ultimoError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get creadaEn =>
      $composableBuilder(column: $table.creadaEn, builder: (column) => ColumnFilters(column));
}

class $$AccionesPendientesTableOrderingComposer extends Composer<_$BaseDatosLocal, $AccionesPendientesTable> {
  $$AccionesPendientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metodo =>
      $composableBuilder(column: $table.metodo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ruta =>
      $composableBuilder(column: $table.ruta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cuerpo =>
      $composableBuilder(column: $table.cuerpo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurso =>
      $composableBuilder(column: $table.recurso, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descripcion =>
      $composableBuilder(column: $table.descripcion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ultimoError =>
      $composableBuilder(column: $table.ultimoError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get creadaEn =>
      $composableBuilder(column: $table.creadaEn, builder: (column) => ColumnOrderings(column));
}

class $$AccionesPendientesTableAnnotationComposer extends Composer<_$BaseDatosLocal, $AccionesPendientesTable> {
  $$AccionesPendientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metodo => $composableBuilder(column: $table.metodo, builder: (column) => column);

  GeneratedColumn<String> get ruta => $composableBuilder(column: $table.ruta, builder: (column) => column);

  GeneratedColumn<String> get cuerpo => $composableBuilder(column: $table.cuerpo, builder: (column) => column);

  GeneratedColumn<String> get recurso => $composableBuilder(column: $table.recurso, builder: (column) => column);

  GeneratedColumn<String> get descripcion =>
      $composableBuilder(column: $table.descripcion, builder: (column) => column);

  GeneratedColumn<String> get estado => $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<int> get intentos => $composableBuilder(column: $table.intentos, builder: (column) => column);

  GeneratedColumn<String> get ultimoError =>
      $composableBuilder(column: $table.ultimoError, builder: (column) => column);

  GeneratedColumn<DateTime> get creadaEn => $composableBuilder(column: $table.creadaEn, builder: (column) => column);
}

class $$AccionesPendientesTableTableManager
    extends
        RootTableManager<
          _$BaseDatosLocal,
          $AccionesPendientesTable,
          FilaAccion,
          $$AccionesPendientesTableFilterComposer,
          $$AccionesPendientesTableOrderingComposer,
          $$AccionesPendientesTableAnnotationComposer,
          $$AccionesPendientesTableCreateCompanionBuilder,
          $$AccionesPendientesTableUpdateCompanionBuilder,
          (FilaAccion, BaseReferences<_$BaseDatosLocal, $AccionesPendientesTable, FilaAccion>),
          FilaAccion,
          PrefetchHooks Function()
        > {
  $$AccionesPendientesTableTableManager(_$BaseDatosLocal db, $AccionesPendientesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AccionesPendientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AccionesPendientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AccionesPendientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> metodo = const Value.absent(),
                Value<String> ruta = const Value.absent(),
                Value<String?> cuerpo = const Value.absent(),
                Value<String> recurso = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<DateTime> creadaEn = const Value.absent(),
              }) => AccionesPendientesCompanion(
                id: id,
                metodo: metodo,
                ruta: ruta,
                cuerpo: cuerpo,
                recurso: recurso,
                descripcion: descripcion,
                estado: estado,
                intentos: intentos,
                ultimoError: ultimoError,
                creadaEn: creadaEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String metodo,
                required String ruta,
                Value<String?> cuerpo = const Value.absent(),
                required String recurso,
                required String descripcion,
                Value<String> estado = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                required DateTime creadaEn,
              }) => AccionesPendientesCompanion.insert(
                id: id,
                metodo: metodo,
                ruta: ruta,
                cuerpo: cuerpo,
                recurso: recurso,
                descripcion: descripcion,
                estado: estado,
                intentos: intentos,
                ultimoError: ultimoError,
                creadaEn: creadaEn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccionesPendientesTable, FilaAccion>(table),
                  BaseReferences<_$BaseDatosLocal, $AccionesPendientesTable, FilaAccion>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccionesPendientesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDatosLocal,
      $AccionesPendientesTable,
      FilaAccion,
      $$AccionesPendientesTableFilterComposer,
      $$AccionesPendientesTableOrderingComposer,
      $$AccionesPendientesTableAnnotationComposer,
      $$AccionesPendientesTableCreateCompanionBuilder,
      $$AccionesPendientesTableUpdateCompanionBuilder,
      (FilaAccion, BaseReferences<_$BaseDatosLocal, $AccionesPendientesTable, FilaAccion>),
      FilaAccion,
      PrefetchHooks Function()
    >;

class $BaseDatosLocalManager {
  final _$BaseDatosLocal _db;
  $BaseDatosLocalManager(this._db);
  $$RespuestasGuardadasTableTableManager get respuestasGuardadas =>
      $$RespuestasGuardadasTableTableManager(_db, _db.respuestasGuardadas);
  $$AccionesPendientesTableTableManager get accionesPendientes =>
      $$AccionesPendientesTableTableManager(_db, _db.accionesPendientes);
}
