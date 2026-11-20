// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SessionLogsTable extends SessionLogs
    with TableInfo<$SessionLogsTable, SessionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseIdMeta = const VerificationMeta(
    'phaseId',
  );
  @override
  late final GeneratedColumn<String> phaseId = GeneratedColumn<String>(
    'phase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionKind>($SessionLogsTable.$converterkind);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _painBeforeMeta = const VerificationMeta(
    'painBefore',
  );
  @override
  late final GeneratedColumn<int> painBefore = GeneratedColumn<int>(
    'pain_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _painAfterMeta = const VerificationMeta(
    'painAfter',
  );
  @override
  late final GeneratedColumn<int> painAfter = GeneratedColumn<int>(
    'pain_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programId,
    phaseId,
    kind,
    startedAt,
    endedAt,
    painBefore,
    painAfter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('phase_id')) {
      context.handle(
        _phaseIdMeta,
        phaseId.isAcceptableOrUnknown(data['phase_id']!, _phaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('pain_before')) {
      context.handle(
        _painBeforeMeta,
        painBefore.isAcceptableOrUnknown(data['pain_before']!, _painBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_painBeforeMeta);
    }
    if (data.containsKey('pain_after')) {
      context.handle(
        _painAfterMeta,
        painAfter.isAcceptableOrUnknown(data['pain_after']!, _painAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_painAfterMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      phaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase_id'],
      )!,
      kind: $SessionLogsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      painBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pain_before'],
      )!,
      painAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pain_after'],
      )!,
    );
  }

  @override
  $SessionLogsTable createAlias(String alias) {
    return $SessionLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionKind, String, String> $converterkind =
      const EnumNameConverter<SessionKind>(SessionKind.values);
}

class SessionLog extends DataClass implements Insertable<SessionLog> {
  final int id;
  final String programId;
  final String phaseId;
  final SessionKind kind;
  final DateTime startedAt;
  final DateTime endedAt;
  final int painBefore;

  /// Worst pain during the session.
  final int painAfter;
  const SessionLog({
    required this.id,
    required this.programId,
    required this.phaseId,
    required this.kind,
    required this.startedAt,
    required this.endedAt,
    required this.painBefore,
    required this.painAfter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<String>(programId);
    map['phase_id'] = Variable<String>(phaseId);
    {
      map['kind'] = Variable<String>(
        $SessionLogsTable.$converterkind.toSql(kind),
      );
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['pain_before'] = Variable<int>(painBefore);
    map['pain_after'] = Variable<int>(painAfter);
    return map;
  }

  SessionLogsCompanion toCompanion(bool nullToAbsent) {
    return SessionLogsCompanion(
      id: Value(id),
      programId: Value(programId),
      phaseId: Value(phaseId),
      kind: Value(kind),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      painBefore: Value(painBefore),
      painAfter: Value(painAfter),
    );
  }

  factory SessionLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionLog(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      phaseId: serializer.fromJson<String>(json['phaseId']),
      kind: $SessionLogsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      painBefore: serializer.fromJson<int>(json['painBefore']),
      painAfter: serializer.fromJson<int>(json['painAfter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<String>(programId),
      'phaseId': serializer.toJson<String>(phaseId),
      'kind': serializer.toJson<String>(
        $SessionLogsTable.$converterkind.toJson(kind),
      ),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'painBefore': serializer.toJson<int>(painBefore),
      'painAfter': serializer.toJson<int>(painAfter),
    };
  }

  SessionLog copyWith({
    int? id,
    String? programId,
    String? phaseId,
    SessionKind? kind,
    DateTime? startedAt,
    DateTime? endedAt,
    int? painBefore,
    int? painAfter,
  }) => SessionLog(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    phaseId: phaseId ?? this.phaseId,
    kind: kind ?? this.kind,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    painBefore: painBefore ?? this.painBefore,
    painAfter: painAfter ?? this.painAfter,
  );
  SessionLog copyWithCompanion(SessionLogsCompanion data) {
    return SessionLog(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      phaseId: data.phaseId.present ? data.phaseId.value : this.phaseId,
      kind: data.kind.present ? data.kind.value : this.kind,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      painBefore: data.painBefore.present
          ? data.painBefore.value
          : this.painBefore,
      painAfter: data.painAfter.present ? data.painAfter.value : this.painAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionLog(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('phaseId: $phaseId, ')
          ..write('kind: $kind, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('painBefore: $painBefore, ')
          ..write('painAfter: $painAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    programId,
    phaseId,
    kind,
    startedAt,
    endedAt,
    painBefore,
    painAfter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionLog &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.phaseId == this.phaseId &&
          other.kind == this.kind &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.painBefore == this.painBefore &&
          other.painAfter == this.painAfter);
}

class SessionLogsCompanion extends UpdateCompanion<SessionLog> {
  final Value<int> id;
  final Value<String> programId;
  final Value<String> phaseId;
  final Value<SessionKind> kind;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> painBefore;
  final Value<int> painAfter;
  const SessionLogsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.phaseId = const Value.absent(),
    this.kind = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.painBefore = const Value.absent(),
    this.painAfter = const Value.absent(),
  });
  SessionLogsCompanion.insert({
    this.id = const Value.absent(),
    required String programId,
    required String phaseId,
    required SessionKind kind,
    required DateTime startedAt,
    required DateTime endedAt,
    required int painBefore,
    required int painAfter,
  }) : programId = Value(programId),
       phaseId = Value(phaseId),
       kind = Value(kind),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       painBefore = Value(painBefore),
       painAfter = Value(painAfter);
  static Insertable<SessionLog> custom({
    Expression<int>? id,
    Expression<String>? programId,
    Expression<String>? phaseId,
    Expression<String>? kind,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? painBefore,
    Expression<int>? painAfter,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (phaseId != null) 'phase_id': phaseId,
      if (kind != null) 'kind': kind,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (painBefore != null) 'pain_before': painBefore,
      if (painAfter != null) 'pain_after': painAfter,
    });
  }

  SessionLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? programId,
    Value<String>? phaseId,
    Value<SessionKind>? kind,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? painBefore,
    Value<int>? painAfter,
  }) {
    return SessionLogsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      phaseId: phaseId ?? this.phaseId,
      kind: kind ?? this.kind,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      painBefore: painBefore ?? this.painBefore,
      painAfter: painAfter ?? this.painAfter,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (phaseId.present) {
      map['phase_id'] = Variable<String>(phaseId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SessionLogsTable.$converterkind.toSql(kind.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (painBefore.present) {
      map['pain_before'] = Variable<int>(painBefore.value);
    }
    if (painAfter.present) {
      map['pain_after'] = Variable<int>(painAfter.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionLogsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('phaseId: $phaseId, ')
          ..write('kind: $kind, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('painBefore: $painBefore, ')
          ..write('painAfter: $painAfter')
          ..write(')'))
        .toString();
  }
}

class $SessionItemLogsTable extends SessionItemLogs
    with TableInfo<$SessionItemLogsTable, SessionItemLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionItemLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES session_logs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setsPlannedMeta = const VerificationMeta(
    'setsPlanned',
  );
  @override
  late final GeneratedColumn<int> setsPlanned = GeneratedColumn<int>(
    'sets_planned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setsDoneMeta = const VerificationMeta(
    'setsDone',
  );
  @override
  late final GeneratedColumn<int> setsDone = GeneratedColumn<int>(
    'sets_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionalMeta = const VerificationMeta(
    'optional',
  );
  @override
  late final GeneratedColumn<bool> optional = GeneratedColumn<bool>(
    'optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("optional" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    exerciseId,
    setsPlanned,
    setsDone,
    optional,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_item_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionItemLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('sets_planned')) {
      context.handle(
        _setsPlannedMeta,
        setsPlanned.isAcceptableOrUnknown(
          data['sets_planned']!,
          _setsPlannedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_setsPlannedMeta);
    }
    if (data.containsKey('sets_done')) {
      context.handle(
        _setsDoneMeta,
        setsDone.isAcceptableOrUnknown(data['sets_done']!, _setsDoneMeta),
      );
    } else if (isInserting) {
      context.missing(_setsDoneMeta);
    }
    if (data.containsKey('optional')) {
      context.handle(
        _optionalMeta,
        optional.isAcceptableOrUnknown(data['optional']!, _optionalMeta),
      );
    } else if (isInserting) {
      context.missing(_optionalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionItemLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionItemLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setsPlanned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sets_planned'],
      )!,
      setsDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sets_done'],
      )!,
      optional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}optional'],
      )!,
    );
  }

  @override
  $SessionItemLogsTable createAlias(String alias) {
    return $SessionItemLogsTable(attachedDatabase, alias);
  }
}

class SessionItemLog extends DataClass implements Insertable<SessionItemLog> {
  final int id;
  final int sessionId;
  final String exerciseId;
  final int setsPlanned;
  final int setsDone;
  final bool optional;
  const SessionItemLog({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setsPlanned,
    required this.setsDone,
    required this.optional,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['sets_planned'] = Variable<int>(setsPlanned);
    map['sets_done'] = Variable<int>(setsDone);
    map['optional'] = Variable<bool>(optional);
    return map;
  }

  SessionItemLogsCompanion toCompanion(bool nullToAbsent) {
    return SessionItemLogsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      setsPlanned: Value(setsPlanned),
      setsDone: Value(setsDone),
      optional: Value(optional),
    );
  }

  factory SessionItemLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionItemLog(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setsPlanned: serializer.fromJson<int>(json['setsPlanned']),
      setsDone: serializer.fromJson<int>(json['setsDone']),
      optional: serializer.fromJson<bool>(json['optional']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setsPlanned': serializer.toJson<int>(setsPlanned),
      'setsDone': serializer.toJson<int>(setsDone),
      'optional': serializer.toJson<bool>(optional),
    };
  }

  SessionItemLog copyWith({
    int? id,
    int? sessionId,
    String? exerciseId,
    int? setsPlanned,
    int? setsDone,
    bool? optional,
  }) => SessionItemLog(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    setsPlanned: setsPlanned ?? this.setsPlanned,
    setsDone: setsDone ?? this.setsDone,
    optional: optional ?? this.optional,
  );
  SessionItemLog copyWithCompanion(SessionItemLogsCompanion data) {
    return SessionItemLog(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setsPlanned: data.setsPlanned.present
          ? data.setsPlanned.value
          : this.setsPlanned,
      setsDone: data.setsDone.present ? data.setsDone.value : this.setsDone,
      optional: data.optional.present ? data.optional.value : this.optional,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionItemLog(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setsPlanned: $setsPlanned, ')
          ..write('setsDone: $setsDone, ')
          ..write('optional: $optional')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, exerciseId, setsPlanned, setsDone, optional);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionItemLog &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.setsPlanned == this.setsPlanned &&
          other.setsDone == this.setsDone &&
          other.optional == this.optional);
}

class SessionItemLogsCompanion extends UpdateCompanion<SessionItemLog> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> exerciseId;
  final Value<int> setsPlanned;
  final Value<int> setsDone;
  final Value<bool> optional;
  const SessionItemLogsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setsPlanned = const Value.absent(),
    this.setsDone = const Value.absent(),
    this.optional = const Value.absent(),
  });
  SessionItemLogsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String exerciseId,
    required int setsPlanned,
    required int setsDone,
    required bool optional,
  }) : sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       setsPlanned = Value(setsPlanned),
       setsDone = Value(setsDone),
       optional = Value(optional);
  static Insertable<SessionItemLog> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? exerciseId,
    Expression<int>? setsPlanned,
    Expression<int>? setsDone,
    Expression<bool>? optional,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setsPlanned != null) 'sets_planned': setsPlanned,
      if (setsDone != null) 'sets_done': setsDone,
      if (optional != null) 'optional': optional,
    });
  }

  SessionItemLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? exerciseId,
    Value<int>? setsPlanned,
    Value<int>? setsDone,
    Value<bool>? optional,
  }) {
    return SessionItemLogsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setsPlanned: setsPlanned ?? this.setsPlanned,
      setsDone: setsDone ?? this.setsDone,
      optional: optional ?? this.optional,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setsPlanned.present) {
      map['sets_planned'] = Variable<int>(setsPlanned.value);
    }
    if (setsDone.present) {
      map['sets_done'] = Variable<int>(setsDone.value);
    }
    if (optional.present) {
      map['optional'] = Variable<bool>(optional.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionItemLogsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setsPlanned: $setsPlanned, ')
          ..write('setsDone: $setsDone, ')
          ..write('optional: $optional')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns with TableInfo<$CheckInsTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kneeMeta = const VerificationMeta('knee');
  @override
  late final GeneratedColumn<String> knee = GeneratedColumn<String>(
    'knee',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('knee'),
  );
  static const VerificationMeta _painMeta = const VerificationMeta('pain');
  @override
  late final GeneratedColumn<int> pain = GeneratedColumn<int>(
    'pain',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Change, String> swelling =
      GeneratedColumn<String>(
        'swelling',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Change>($CheckInsTable.$converterswelling);
  @override
  late final GeneratedColumnWithTypeConverter<Change, String> stiffness =
      GeneratedColumn<String>(
        'stiffness',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Change>($CheckInsTable.$converterstiffness);
  static const VerificationMeta _loadPainMeta = const VerificationMeta(
    'loadPain',
  );
  @override
  late final GeneratedColumn<int> loadPain = GeneratedColumn<int>(
    'load_pain',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    knee,
    pain,
    swelling,
    stiffness,
    loadPain,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('knee')) {
      context.handle(
        _kneeMeta,
        knee.isAcceptableOrUnknown(data['knee']!, _kneeMeta),
      );
    }
    if (data.containsKey('pain')) {
      context.handle(
        _painMeta,
        pain.isAcceptableOrUnknown(data['pain']!, _painMeta),
      );
    } else if (isInserting) {
      context.missing(_painMeta);
    }
    if (data.containsKey('load_pain')) {
      context.handle(
        _loadPainMeta,
        loadPain.isAcceptableOrUnknown(data['load_pain']!, _loadPainMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, knee};
  @override
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      knee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}knee'],
      )!,
      pain: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pain'],
      )!,
      swelling: $CheckInsTable.$converterswelling.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}swelling'],
        )!,
      ),
      stiffness: $CheckInsTable.$converterstiffness.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}stiffness'],
        )!,
      ),
      loadPain: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}load_pain'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Change, String, String> $converterswelling =
      const EnumNameConverter<Change>(Change.values);
  static JsonTypeConverter2<Change, String, String> $converterstiffness =
      const EnumNameConverter<Change>(Change.values);
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  /// Local date, `yyyy-mm-dd`.
  final String day;

  /// "left" or "right" when both knees are in rehab, else "knee".
  final String knee;
  final int pain;
  final Change swelling;
  final Change stiffness;

  /// Pain 0–10 on the program's morning load test (e.g. a single-leg
  /// squat for the patellar tendon). Null when not asked or skipped.
  final int? loadPain;
  final DateTime recordedAt;
  const CheckIn({
    required this.day,
    required this.knee,
    required this.pain,
    required this.swelling,
    required this.stiffness,
    this.loadPain,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['knee'] = Variable<String>(knee);
    map['pain'] = Variable<int>(pain);
    {
      map['swelling'] = Variable<String>(
        $CheckInsTable.$converterswelling.toSql(swelling),
      );
    }
    {
      map['stiffness'] = Variable<String>(
        $CheckInsTable.$converterstiffness.toSql(stiffness),
      );
    }
    if (!nullToAbsent || loadPain != null) {
      map['load_pain'] = Variable<int>(loadPain);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      day: Value(day),
      knee: Value(knee),
      pain: Value(pain),
      swelling: Value(swelling),
      stiffness: Value(stiffness),
      loadPain: loadPain == null && nullToAbsent
          ? const Value.absent()
          : Value(loadPain),
      recordedAt: Value(recordedAt),
    );
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(
      day: serializer.fromJson<String>(json['day']),
      knee: serializer.fromJson<String>(json['knee']),
      pain: serializer.fromJson<int>(json['pain']),
      swelling: $CheckInsTable.$converterswelling.fromJson(
        serializer.fromJson<String>(json['swelling']),
      ),
      stiffness: $CheckInsTable.$converterstiffness.fromJson(
        serializer.fromJson<String>(json['stiffness']),
      ),
      loadPain: serializer.fromJson<int?>(json['loadPain']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'knee': serializer.toJson<String>(knee),
      'pain': serializer.toJson<int>(pain),
      'swelling': serializer.toJson<String>(
        $CheckInsTable.$converterswelling.toJson(swelling),
      ),
      'stiffness': serializer.toJson<String>(
        $CheckInsTable.$converterstiffness.toJson(stiffness),
      ),
      'loadPain': serializer.toJson<int?>(loadPain),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  CheckIn copyWith({
    String? day,
    String? knee,
    int? pain,
    Change? swelling,
    Change? stiffness,
    Value<int?> loadPain = const Value.absent(),
    DateTime? recordedAt,
  }) => CheckIn(
    day: day ?? this.day,
    knee: knee ?? this.knee,
    pain: pain ?? this.pain,
    swelling: swelling ?? this.swelling,
    stiffness: stiffness ?? this.stiffness,
    loadPain: loadPain.present ? loadPain.value : this.loadPain,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  CheckIn copyWithCompanion(CheckInsCompanion data) {
    return CheckIn(
      day: data.day.present ? data.day.value : this.day,
      knee: data.knee.present ? data.knee.value : this.knee,
      pain: data.pain.present ? data.pain.value : this.pain,
      swelling: data.swelling.present ? data.swelling.value : this.swelling,
      stiffness: data.stiffness.present ? data.stiffness.value : this.stiffness,
      loadPain: data.loadPain.present ? data.loadPain.value : this.loadPain,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('day: $day, ')
          ..write('knee: $knee, ')
          ..write('pain: $pain, ')
          ..write('swelling: $swelling, ')
          ..write('stiffness: $stiffness, ')
          ..write('loadPain: $loadPain, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(day, knee, pain, swelling, stiffness, loadPain, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckIn &&
          other.day == this.day &&
          other.knee == this.knee &&
          other.pain == this.pain &&
          other.swelling == this.swelling &&
          other.stiffness == this.stiffness &&
          other.loadPain == this.loadPain &&
          other.recordedAt == this.recordedAt);
}

class CheckInsCompanion extends UpdateCompanion<CheckIn> {
  final Value<String> day;
  final Value<String> knee;
  final Value<int> pain;
  final Value<Change> swelling;
  final Value<Change> stiffness;
  final Value<int?> loadPain;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const CheckInsCompanion({
    this.day = const Value.absent(),
    this.knee = const Value.absent(),
    this.pain = const Value.absent(),
    this.swelling = const Value.absent(),
    this.stiffness = const Value.absent(),
    this.loadPain = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckInsCompanion.insert({
    required String day,
    this.knee = const Value.absent(),
    required int pain,
    required Change swelling,
    required Change stiffness,
    this.loadPain = const Value.absent(),
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       pain = Value(pain),
       swelling = Value(swelling),
       stiffness = Value(stiffness),
       recordedAt = Value(recordedAt);
  static Insertable<CheckIn> custom({
    Expression<String>? day,
    Expression<String>? knee,
    Expression<int>? pain,
    Expression<String>? swelling,
    Expression<String>? stiffness,
    Expression<int>? loadPain,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (knee != null) 'knee': knee,
      if (pain != null) 'pain': pain,
      if (swelling != null) 'swelling': swelling,
      if (stiffness != null) 'stiffness': stiffness,
      if (loadPain != null) 'load_pain': loadPain,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckInsCompanion copyWith({
    Value<String>? day,
    Value<String>? knee,
    Value<int>? pain,
    Value<Change>? swelling,
    Value<Change>? stiffness,
    Value<int?>? loadPain,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return CheckInsCompanion(
      day: day ?? this.day,
      knee: knee ?? this.knee,
      pain: pain ?? this.pain,
      swelling: swelling ?? this.swelling,
      stiffness: stiffness ?? this.stiffness,
      loadPain: loadPain ?? this.loadPain,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (knee.present) {
      map['knee'] = Variable<String>(knee.value);
    }
    if (pain.present) {
      map['pain'] = Variable<int>(pain.value);
    }
    if (swelling.present) {
      map['swelling'] = Variable<String>(
        $CheckInsTable.$converterswelling.toSql(swelling.value),
      );
    }
    if (stiffness.present) {
      map['stiffness'] = Variable<String>(
        $CheckInsTable.$converterstiffness.toSql(stiffness.value),
      );
    }
    if (loadPain.present) {
      map['load_pain'] = Variable<int>(loadPain.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('day: $day, ')
          ..write('knee: $knee, ')
          ..write('pain: $pain, ')
          ..write('swelling: $swelling, ')
          ..write('stiffness: $stiffness, ')
          ..write('loadPain: $loadPain, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhaseEventsTable extends PhaseEvents
    with TableInfo<$PhaseEventsTable, PhaseEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhaseEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseIdMeta = const VerificationMeta(
    'phaseId',
  );
  @override
  late final GeneratedColumn<String> phaseId = GeneratedColumn<String>(
    'phase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PhaseEventKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PhaseEventKind>($PhaseEventsTable.$converterkind);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, programId, phaseId, kind, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'phase_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhaseEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('phase_id')) {
      context.handle(
        _phaseIdMeta,
        phaseId.isAcceptableOrUnknown(data['phase_id']!, _phaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhaseEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhaseEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      phaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase_id'],
      )!,
      kind: $PhaseEventsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $PhaseEventsTable createAlias(String alias) {
    return $PhaseEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PhaseEventKind, String, String> $converterkind =
      const EnumNameConverter<PhaseEventKind>(PhaseEventKind.values);
}

class PhaseEvent extends DataClass implements Insertable<PhaseEvent> {
  final int id;
  final String programId;

  /// The phase you are in from [at] on.
  final String phaseId;
  final PhaseEventKind kind;
  final DateTime at;
  const PhaseEvent({
    required this.id,
    required this.programId,
    required this.phaseId,
    required this.kind,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<String>(programId);
    map['phase_id'] = Variable<String>(phaseId);
    {
      map['kind'] = Variable<String>(
        $PhaseEventsTable.$converterkind.toSql(kind),
      );
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  PhaseEventsCompanion toCompanion(bool nullToAbsent) {
    return PhaseEventsCompanion(
      id: Value(id),
      programId: Value(programId),
      phaseId: Value(phaseId),
      kind: Value(kind),
      at: Value(at),
    );
  }

  factory PhaseEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhaseEvent(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      phaseId: serializer.fromJson<String>(json['phaseId']),
      kind: $PhaseEventsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<String>(programId),
      'phaseId': serializer.toJson<String>(phaseId),
      'kind': serializer.toJson<String>(
        $PhaseEventsTable.$converterkind.toJson(kind),
      ),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  PhaseEvent copyWith({
    int? id,
    String? programId,
    String? phaseId,
    PhaseEventKind? kind,
    DateTime? at,
  }) => PhaseEvent(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    phaseId: phaseId ?? this.phaseId,
    kind: kind ?? this.kind,
    at: at ?? this.at,
  );
  PhaseEvent copyWithCompanion(PhaseEventsCompanion data) {
    return PhaseEvent(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      phaseId: data.phaseId.present ? data.phaseId.value : this.phaseId,
      kind: data.kind.present ? data.kind.value : this.kind,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhaseEvent(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('phaseId: $phaseId, ')
          ..write('kind: $kind, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, programId, phaseId, kind, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhaseEvent &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.phaseId == this.phaseId &&
          other.kind == this.kind &&
          other.at == this.at);
}

class PhaseEventsCompanion extends UpdateCompanion<PhaseEvent> {
  final Value<int> id;
  final Value<String> programId;
  final Value<String> phaseId;
  final Value<PhaseEventKind> kind;
  final Value<DateTime> at;
  const PhaseEventsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.phaseId = const Value.absent(),
    this.kind = const Value.absent(),
    this.at = const Value.absent(),
  });
  PhaseEventsCompanion.insert({
    this.id = const Value.absent(),
    required String programId,
    required String phaseId,
    required PhaseEventKind kind,
    required DateTime at,
  }) : programId = Value(programId),
       phaseId = Value(phaseId),
       kind = Value(kind),
       at = Value(at);
  static Insertable<PhaseEvent> custom({
    Expression<int>? id,
    Expression<String>? programId,
    Expression<String>? phaseId,
    Expression<String>? kind,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (phaseId != null) 'phase_id': phaseId,
      if (kind != null) 'kind': kind,
      if (at != null) 'at': at,
    });
  }

  PhaseEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? programId,
    Value<String>? phaseId,
    Value<PhaseEventKind>? kind,
    Value<DateTime>? at,
  }) {
    return PhaseEventsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      phaseId: phaseId ?? this.phaseId,
      kind: kind ?? this.kind,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (phaseId.present) {
      map['phase_id'] = Variable<String>(phaseId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PhaseEventsTable.$converterkind.toSql(kind.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhaseEventsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('phaseId: $phaseId, ')
          ..write('kind: $kind, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $GateResultsTable extends GateResults
    with TableInfo<$GateResultsTable, GateResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GateResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseIdMeta = const VerificationMeta(
    'phaseId',
  );
  @override
  late final GeneratedColumn<String> phaseId = GeneratedColumn<String>(
    'phase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criterionIdMeta = const VerificationMeta(
    'criterionId',
  );
  @override
  late final GeneratedColumn<String> criterionId = GeneratedColumn<String>(
    'criterion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passedMeta = const VerificationMeta('passed');
  @override
  late final GeneratedColumn<bool> passed = GeneratedColumn<bool>(
    'passed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("passed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programId,
    phaseId,
    criterionId,
    passed,
    value,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gate_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<GateResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('phase_id')) {
      context.handle(
        _phaseIdMeta,
        phaseId.isAcceptableOrUnknown(data['phase_id']!, _phaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseIdMeta);
    }
    if (data.containsKey('criterion_id')) {
      context.handle(
        _criterionIdMeta,
        criterionId.isAcceptableOrUnknown(
          data['criterion_id']!,
          _criterionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_criterionIdMeta);
    }
    if (data.containsKey('passed')) {
      context.handle(
        _passedMeta,
        passed.isAcceptableOrUnknown(data['passed']!, _passedMeta),
      );
    } else if (isInserting) {
      context.missing(_passedMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GateResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GateResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      phaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase_id'],
      )!,
      criterionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criterion_id'],
      )!,
      passed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}passed'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $GateResultsTable createAlias(String alias) {
    return $GateResultsTable(attachedDatabase, alias);
  }
}

class GateResult extends DataClass implements Insertable<GateResult> {
  final int id;
  final String programId;
  final String phaseId;
  final String criterionId;
  final bool passed;

  /// Measured value for number criteria, e.g. seconds of balance.
  final double? value;
  final DateTime at;
  const GateResult({
    required this.id,
    required this.programId,
    required this.phaseId,
    required this.criterionId,
    required this.passed,
    this.value,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<String>(programId);
    map['phase_id'] = Variable<String>(phaseId);
    map['criterion_id'] = Variable<String>(criterionId);
    map['passed'] = Variable<bool>(passed);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  GateResultsCompanion toCompanion(bool nullToAbsent) {
    return GateResultsCompanion(
      id: Value(id),
      programId: Value(programId),
      phaseId: Value(phaseId),
      criterionId: Value(criterionId),
      passed: Value(passed),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      at: Value(at),
    );
  }

  factory GateResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GateResult(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      phaseId: serializer.fromJson<String>(json['phaseId']),
      criterionId: serializer.fromJson<String>(json['criterionId']),
      passed: serializer.fromJson<bool>(json['passed']),
      value: serializer.fromJson<double?>(json['value']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<String>(programId),
      'phaseId': serializer.toJson<String>(phaseId),
      'criterionId': serializer.toJson<String>(criterionId),
      'passed': serializer.toJson<bool>(passed),
      'value': serializer.toJson<double?>(value),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  GateResult copyWith({
    int? id,
    String? programId,
    String? phaseId,
    String? criterionId,
    bool? passed,
    Value<double?> value = const Value.absent(),
    DateTime? at,
  }) => GateResult(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    phaseId: phaseId ?? this.phaseId,
    criterionId: criterionId ?? this.criterionId,
    passed: passed ?? this.passed,
    value: value.present ? value.value : this.value,
    at: at ?? this.at,
  );
  GateResult copyWithCompanion(GateResultsCompanion data) {
    return GateResult(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      phaseId: data.phaseId.present ? data.phaseId.value : this.phaseId,
      criterionId: data.criterionId.present
          ? data.criterionId.value
          : this.criterionId,
      passed: data.passed.present ? data.passed.value : this.passed,
      value: data.value.present ? data.value.value : this.value,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GateResult(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('phaseId: $phaseId, ')
          ..write('criterionId: $criterionId, ')
          ..write('passed: $passed, ')
          ..write('value: $value, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, programId, phaseId, criterionId, passed, value, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GateResult &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.phaseId == this.phaseId &&
          other.criterionId == this.criterionId &&
          other.passed == this.passed &&
          other.value == this.value &&
          other.at == this.at);
}

class GateResultsCompanion extends UpdateCompanion<GateResult> {
  final Value<int> id;
  final Value<String> programId;
  final Value<String> phaseId;
  final Value<String> criterionId;
  final Value<bool> passed;
  final Value<double?> value;
  final Value<DateTime> at;
  const GateResultsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.phaseId = const Value.absent(),
    this.criterionId = const Value.absent(),
    this.passed = const Value.absent(),
    this.value = const Value.absent(),
    this.at = const Value.absent(),
  });
  GateResultsCompanion.insert({
    this.id = const Value.absent(),
    required String programId,
    required String phaseId,
    required String criterionId,
    required bool passed,
    this.value = const Value.absent(),
    required DateTime at,
  }) : programId = Value(programId),
       phaseId = Value(phaseId),
       criterionId = Value(criterionId),
       passed = Value(passed),
       at = Value(at);
  static Insertable<GateResult> custom({
    Expression<int>? id,
    Expression<String>? programId,
    Expression<String>? phaseId,
    Expression<String>? criterionId,
    Expression<bool>? passed,
    Expression<double>? value,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (phaseId != null) 'phase_id': phaseId,
      if (criterionId != null) 'criterion_id': criterionId,
      if (passed != null) 'passed': passed,
      if (value != null) 'value': value,
      if (at != null) 'at': at,
    });
  }

  GateResultsCompanion copyWith({
    Value<int>? id,
    Value<String>? programId,
    Value<String>? phaseId,
    Value<String>? criterionId,
    Value<bool>? passed,
    Value<double?>? value,
    Value<DateTime>? at,
  }) {
    return GateResultsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      phaseId: phaseId ?? this.phaseId,
      criterionId: criterionId ?? this.criterionId,
      passed: passed ?? this.passed,
      value: value ?? this.value,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (phaseId.present) {
      map['phase_id'] = Variable<String>(phaseId.value);
    }
    if (criterionId.present) {
      map['criterion_id'] = Variable<String>(criterionId.value);
    }
    if (passed.present) {
      map['passed'] = Variable<bool>(passed.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GateResultsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('phaseId: $phaseId, ')
          ..write('criterionId: $criterionId, ')
          ..write('passed: $passed, ')
          ..write('value: $value, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionLogsTable sessionLogs = $SessionLogsTable(this);
  late final $SessionItemLogsTable sessionItemLogs = $SessionItemLogsTable(
    this,
  );
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $PhaseEventsTable phaseEvents = $PhaseEventsTable(this);
  late final $GateResultsTable gateResults = $GateResultsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessionLogs,
    sessionItemLogs,
    checkIns,
    phaseEvents,
    gateResults,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_logs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_item_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SessionLogsTableCreateCompanionBuilder =
    SessionLogsCompanion Function({
      Value<int> id,
      required String programId,
      required String phaseId,
      required SessionKind kind,
      required DateTime startedAt,
      required DateTime endedAt,
      required int painBefore,
      required int painAfter,
    });
typedef $$SessionLogsTableUpdateCompanionBuilder =
    SessionLogsCompanion Function({
      Value<int> id,
      Value<String> programId,
      Value<String> phaseId,
      Value<SessionKind> kind,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> painBefore,
      Value<int> painAfter,
    });

final class $$SessionLogsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionLogsTable, SessionLog> {
  $$SessionLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionItemLogsTable, List<SessionItemLog>>
  _sessionItemLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionItemLogs,
    aliasName: 'session_logs__id__session_item_logs__session_id',
  );

  $$SessionItemLogsTableProcessedTableManager get sessionItemLogsRefs {
    final manager = $$SessionItemLogsTableTableManager(
      $_db,
      $_db.sessionItemLogs,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionItemLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phaseId => $composableBuilder(
    column: $table.phaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionKind, SessionKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get painBefore => $composableBuilder(
    column: $table.painBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get painAfter => $composableBuilder(
    column: $table.painAfter,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionItemLogsRefs(
    Expression<bool> Function($$SessionItemLogsTableFilterComposer f) f,
  ) {
    final $$SessionItemLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionItemLogs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionItemLogsTableFilterComposer(
            $db: $db,
            $table: $db.sessionItemLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phaseId => $composableBuilder(
    column: $table.phaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get painBefore => $composableBuilder(
    column: $table.painBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get painAfter => $composableBuilder(
    column: $table.painAfter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<String> get phaseId =>
      $composableBuilder(column: $table.phaseId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get painBefore => $composableBuilder(
    column: $table.painBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get painAfter =>
      $composableBuilder(column: $table.painAfter, builder: (column) => column);

  Expression<T> sessionItemLogsRefs<T extends Object>(
    Expression<T> Function($$SessionItemLogsTableAnnotationComposer a) f,
  ) {
    final $$SessionItemLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionItemLogs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionItemLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionItemLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionLogsTable,
          SessionLog,
          $$SessionLogsTableFilterComposer,
          $$SessionLogsTableOrderingComposer,
          $$SessionLogsTableAnnotationComposer,
          $$SessionLogsTableCreateCompanionBuilder,
          $$SessionLogsTableUpdateCompanionBuilder,
          (SessionLog, $$SessionLogsTableReferences),
          SessionLog,
          PrefetchHooks Function({bool sessionItemLogsRefs})
        > {
  $$SessionLogsTableTableManager(_$AppDatabase db, $SessionLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<String> phaseId = const Value.absent(),
                Value<SessionKind> kind = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> painBefore = const Value.absent(),
                Value<int> painAfter = const Value.absent(),
              }) => SessionLogsCompanion(
                id: id,
                programId: programId,
                phaseId: phaseId,
                kind: kind,
                startedAt: startedAt,
                endedAt: endedAt,
                painBefore: painBefore,
                painAfter: painAfter,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String programId,
                required String phaseId,
                required SessionKind kind,
                required DateTime startedAt,
                required DateTime endedAt,
                required int painBefore,
                required int painAfter,
              }) => SessionLogsCompanion.insert(
                id: id,
                programId: programId,
                phaseId: phaseId,
                kind: kind,
                startedAt: startedAt,
                endedAt: endedAt,
                painBefore: painBefore,
                painAfter: painAfter,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionLogsTable, SessionLog>(table),
                  $$SessionLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionItemLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionItemLogsRefs) db.sessionItemLogs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionItemLogsRefs)
                    await $_getPrefetchedDataByColumns<
                      SessionLog,
                      $SessionLogsTable,
                      SessionItemLog,
                      $SessionItemLogsTable
                    >(
                      currentTable: table,
                      referencedTable: $$SessionLogsTableReferences
                          ._sessionItemLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SessionLogsTableReferences(
                            db,
                            table,
                            p0,
                          ).sessionItemLogsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionLogsTable,
      SessionLog,
      $$SessionLogsTableFilterComposer,
      $$SessionLogsTableOrderingComposer,
      $$SessionLogsTableAnnotationComposer,
      $$SessionLogsTableCreateCompanionBuilder,
      $$SessionLogsTableUpdateCompanionBuilder,
      (SessionLog, $$SessionLogsTableReferences),
      SessionLog,
      PrefetchHooks Function({bool sessionItemLogsRefs})
    >;
typedef $$SessionItemLogsTableCreateCompanionBuilder =
    SessionItemLogsCompanion Function({
      Value<int> id,
      required int sessionId,
      required String exerciseId,
      required int setsPlanned,
      required int setsDone,
      required bool optional,
    });
typedef $$SessionItemLogsTableUpdateCompanionBuilder =
    SessionItemLogsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> exerciseId,
      Value<int> setsPlanned,
      Value<int> setsDone,
      Value<bool> optional,
    });

final class $$SessionItemLogsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionItemLogsTable, SessionItemLog> {
  $$SessionItemLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionLogsTable _sessionIdTable(_$AppDatabase db) => db.sessionLogs
      .createAlias('session_item_logs__session_id__session_logs__id');

  $$SessionLogsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionLogsTableTableManager(
      $_db,
      $_db.sessionLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionItemLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionItemLogsTable> {
  $$SessionItemLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setsPlanned => $composableBuilder(
    column: $table.setsPlanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setsDone => $composableBuilder(
    column: $table.setsDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get optional => $composableBuilder(
    column: $table.optional,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionLogsTableFilterComposer get sessionId {
    final $$SessionLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableFilterComposer(
            $db: $db,
            $table: $db.sessionLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionItemLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionItemLogsTable> {
  $$SessionItemLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setsPlanned => $composableBuilder(
    column: $table.setsPlanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setsDone => $composableBuilder(
    column: $table.setsDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get optional => $composableBuilder(
    column: $table.optional,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionLogsTableOrderingComposer get sessionId {
    final $$SessionLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableOrderingComposer(
            $db: $db,
            $table: $db.sessionLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionItemLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionItemLogsTable> {
  $$SessionItemLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setsPlanned => $composableBuilder(
    column: $table.setsPlanned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setsDone =>
      $composableBuilder(column: $table.setsDone, builder: (column) => column);

  GeneratedColumn<bool> get optional =>
      $composableBuilder(column: $table.optional, builder: (column) => column);

  $$SessionLogsTableAnnotationComposer get sessionId {
    final $$SessionLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionItemLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionItemLogsTable,
          SessionItemLog,
          $$SessionItemLogsTableFilterComposer,
          $$SessionItemLogsTableOrderingComposer,
          $$SessionItemLogsTableAnnotationComposer,
          $$SessionItemLogsTableCreateCompanionBuilder,
          $$SessionItemLogsTableUpdateCompanionBuilder,
          (SessionItemLog, $$SessionItemLogsTableReferences),
          SessionItemLog,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionItemLogsTableTableManager(
    _$AppDatabase db,
    $SessionItemLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionItemLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionItemLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionItemLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setsPlanned = const Value.absent(),
                Value<int> setsDone = const Value.absent(),
                Value<bool> optional = const Value.absent(),
              }) => SessionItemLogsCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                setsPlanned: setsPlanned,
                setsDone: setsDone,
                optional: optional,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String exerciseId,
                required int setsPlanned,
                required int setsDone,
                required bool optional,
              }) => SessionItemLogsCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                setsPlanned: setsPlanned,
                setsDone: setsDone,
                optional: optional,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionItemLogsTable, SessionItemLog>(table),
                  $$SessionItemLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SessionItemLogsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SessionItemLogsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionItemLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionItemLogsTable,
      SessionItemLog,
      $$SessionItemLogsTableFilterComposer,
      $$SessionItemLogsTableOrderingComposer,
      $$SessionItemLogsTableAnnotationComposer,
      $$SessionItemLogsTableCreateCompanionBuilder,
      $$SessionItemLogsTableUpdateCompanionBuilder,
      (SessionItemLog, $$SessionItemLogsTableReferences),
      SessionItemLog,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$CheckInsTableCreateCompanionBuilder = CheckInsCompanion Function({
  required String day,
  Value<String> knee,
  required int pain,
  required Change swelling,
  required Change stiffness,
  Value<int?> loadPain,
  required DateTime recordedAt,
  Value<int> rowid,
});
typedef $$CheckInsTableUpdateCompanionBuilder = CheckInsCompanion Function({
  Value<String> day,
  Value<String> knee,
  Value<int> pain,
  Value<Change> swelling,
  Value<Change> stiffness,
  Value<int?> loadPain,
  Value<DateTime> recordedAt,
  Value<int> rowid,
});

class $$CheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knee => $composableBuilder(
    column: $table.knee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pain => $composableBuilder(
    column: $table.pain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Change, Change, String> get swelling =>
      $composableBuilder(
        column: $table.swelling,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Change, Change, String> get stiffness =>
      $composableBuilder(
        column: $table.stiffness,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get loadPain => $composableBuilder(
    column: $table.loadPain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knee => $composableBuilder(
    column: $table.knee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pain => $composableBuilder(
    column: $table.pain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get swelling => $composableBuilder(
    column: $table.swelling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stiffness => $composableBuilder(
    column: $table.stiffness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loadPain => $composableBuilder(
    column: $table.loadPain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get knee =>
      $composableBuilder(column: $table.knee, builder: (column) => column);

  GeneratedColumn<int> get pain =>
      $composableBuilder(column: $table.pain, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Change, String> get swelling =>
      $composableBuilder(column: $table.swelling, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Change, String> get stiffness =>
      $composableBuilder(column: $table.stiffness, builder: (column) => column);

  GeneratedColumn<int> get loadPain =>
      $composableBuilder(column: $table.loadPain, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckInsTable,
          CheckIn,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckIn, BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>),
          CheckIn,
          PrefetchHooks Function()
        > {
  $$CheckInsTableTableManager(_$AppDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<String> knee = const Value.absent(),
                Value<int> pain = const Value.absent(),
                Value<Change> swelling = const Value.absent(),
                Value<Change> stiffness = const Value.absent(),
                Value<int?> loadPain = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion(
                day: day,
                knee: knee,
                pain: pain,
                swelling: swelling,
                stiffness: stiffness,
                loadPain: loadPain,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                Value<String> knee = const Value.absent(),
                required int pain,
                required Change swelling,
                required Change stiffness,
                Value<int?> loadPain = const Value.absent(),
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion.insert(
                day: day,
                knee: knee,
                pain: pain,
                swelling: swelling,
                stiffness: stiffness,
                loadPain: loadPain,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckInsTable, CheckIn>(table),
                  BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckInsTable,
      CheckIn,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckIn, BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>),
      CheckIn,
      PrefetchHooks Function()
    >;
typedef $$PhaseEventsTableCreateCompanionBuilder =
    PhaseEventsCompanion Function({
      Value<int> id,
      required String programId,
      required String phaseId,
      required PhaseEventKind kind,
      required DateTime at,
    });
typedef $$PhaseEventsTableUpdateCompanionBuilder =
    PhaseEventsCompanion Function({
      Value<int> id,
      Value<String> programId,
      Value<String> phaseId,
      Value<PhaseEventKind> kind,
      Value<DateTime> at,
    });

class $$PhaseEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PhaseEventsTable> {
  $$PhaseEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phaseId => $composableBuilder(
    column: $table.phaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PhaseEventKind, PhaseEventKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhaseEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhaseEventsTable> {
  $$PhaseEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phaseId => $composableBuilder(
    column: $table.phaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhaseEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhaseEventsTable> {
  $$PhaseEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<String> get phaseId =>
      $composableBuilder(column: $table.phaseId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PhaseEventKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$PhaseEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhaseEventsTable,
          PhaseEvent,
          $$PhaseEventsTableFilterComposer,
          $$PhaseEventsTableOrderingComposer,
          $$PhaseEventsTableAnnotationComposer,
          $$PhaseEventsTableCreateCompanionBuilder,
          $$PhaseEventsTableUpdateCompanionBuilder,
          (
            PhaseEvent,
            BaseReferences<_$AppDatabase, $PhaseEventsTable, PhaseEvent>,
          ),
          PhaseEvent,
          PrefetchHooks Function()
        > {
  $$PhaseEventsTableTableManager(_$AppDatabase db, $PhaseEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhaseEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhaseEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhaseEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<String> phaseId = const Value.absent(),
                Value<PhaseEventKind> kind = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => PhaseEventsCompanion(
                id: id,
                programId: programId,
                phaseId: phaseId,
                kind: kind,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String programId,
                required String phaseId,
                required PhaseEventKind kind,
                required DateTime at,
              }) => PhaseEventsCompanion.insert(
                id: id,
                programId: programId,
                phaseId: phaseId,
                kind: kind,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhaseEventsTable, PhaseEvent>(table),
                  BaseReferences<_$AppDatabase, $PhaseEventsTable, PhaseEvent>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhaseEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhaseEventsTable,
      PhaseEvent,
      $$PhaseEventsTableFilterComposer,
      $$PhaseEventsTableOrderingComposer,
      $$PhaseEventsTableAnnotationComposer,
      $$PhaseEventsTableCreateCompanionBuilder,
      $$PhaseEventsTableUpdateCompanionBuilder,
      (
        PhaseEvent,
        BaseReferences<_$AppDatabase, $PhaseEventsTable, PhaseEvent>,
      ),
      PhaseEvent,
      PrefetchHooks Function()
    >;
typedef $$GateResultsTableCreateCompanionBuilder =
    GateResultsCompanion Function({
      Value<int> id,
      required String programId,
      required String phaseId,
      required String criterionId,
      required bool passed,
      Value<double?> value,
      required DateTime at,
    });
typedef $$GateResultsTableUpdateCompanionBuilder =
    GateResultsCompanion Function({
      Value<int> id,
      Value<String> programId,
      Value<String> phaseId,
      Value<String> criterionId,
      Value<bool> passed,
      Value<double?> value,
      Value<DateTime> at,
    });

class $$GateResultsTableFilterComposer
    extends Composer<_$AppDatabase, $GateResultsTable> {
  $$GateResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phaseId => $composableBuilder(
    column: $table.phaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criterionId => $composableBuilder(
    column: $table.criterionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GateResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $GateResultsTable> {
  $$GateResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phaseId => $composableBuilder(
    column: $table.phaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criterionId => $composableBuilder(
    column: $table.criterionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GateResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GateResultsTable> {
  $$GateResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<String> get phaseId =>
      $composableBuilder(column: $table.phaseId, builder: (column) => column);

  GeneratedColumn<String> get criterionId => $composableBuilder(
    column: $table.criterionId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get passed =>
      $composableBuilder(column: $table.passed, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$GateResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GateResultsTable,
          GateResult,
          $$GateResultsTableFilterComposer,
          $$GateResultsTableOrderingComposer,
          $$GateResultsTableAnnotationComposer,
          $$GateResultsTableCreateCompanionBuilder,
          $$GateResultsTableUpdateCompanionBuilder,
          (
            GateResult,
            BaseReferences<_$AppDatabase, $GateResultsTable, GateResult>,
          ),
          GateResult,
          PrefetchHooks Function()
        > {
  $$GateResultsTableTableManager(_$AppDatabase db, $GateResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GateResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GateResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GateResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<String> phaseId = const Value.absent(),
                Value<String> criterionId = const Value.absent(),
                Value<bool> passed = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => GateResultsCompanion(
                id: id,
                programId: programId,
                phaseId: phaseId,
                criterionId: criterionId,
                passed: passed,
                value: value,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String programId,
                required String phaseId,
                required String criterionId,
                required bool passed,
                Value<double?> value = const Value.absent(),
                required DateTime at,
              }) => GateResultsCompanion.insert(
                id: id,
                programId: programId,
                phaseId: phaseId,
                criterionId: criterionId,
                passed: passed,
                value: value,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GateResultsTable, GateResult>(table),
                  BaseReferences<_$AppDatabase, $GateResultsTable, GateResult>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GateResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GateResultsTable,
      GateResult,
      $$GateResultsTableFilterComposer,
      $$GateResultsTableOrderingComposer,
      $$GateResultsTableAnnotationComposer,
      $$GateResultsTableCreateCompanionBuilder,
      $$GateResultsTableUpdateCompanionBuilder,
      (
        GateResult,
        BaseReferences<_$AppDatabase, $GateResultsTable, GateResult>,
      ),
      GateResult,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionLogsTableTableManager get sessionLogs =>
      $$SessionLogsTableTableManager(_db, _db.sessionLogs);
  $$SessionItemLogsTableTableManager get sessionItemLogs =>
      $$SessionItemLogsTableTableManager(_db, _db.sessionItemLogs);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$PhaseEventsTableTableManager get phaseEvents =>
      $$PhaseEventsTableTableManager(_db, _db.phaseEvents);
  $$GateResultsTableTableManager get gateResults =>
      $$GateResultsTableTableManager(_db, _db.gateResults);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
