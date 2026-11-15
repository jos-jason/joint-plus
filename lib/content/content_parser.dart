import 'models.dart';

/// Thrown when content JSON is malformed or inconsistent. Lists every problem
/// found, each prefixed with where it is, so a bad edit is quick to locate.
class ContentException implements Exception {
  ContentException(this.errors);

  final List<String> errors;

  @override
  String toString() =>
      'ContentException (${errors.length}):\n  ${errors.join('\n  ')}';
}

/// Turns decoded JSON into a validated [ContentLibrary].
///
/// Collects all errors rather than stopping at the first, then throws a single
/// [ContentException] if anything is wrong.
class ContentParser {
  ContentParser._();

  static ContentLibrary parse({
    required Object? exercisesJson,
    required List<Object?> programsJson,
  }) {
    final errors = <String>[];

    final exercises = _parseExercises(exercisesJson, errors);
    final programs = [
      for (var i = 0; i < programsJson.length; i++)
        ?_parseProgram(programsJson[i], 'programs[$i]', errors),
    ];

    _validate(exercises, programs, errors);

    if (errors.isNotEmpty) throw ContentException(errors);
    return ContentLibrary(exercises: exercises, programs: programs);
  }

  // ---------------------------------------------------------------- exercises

  static Map<String, Exercise> _parseExercises(
    Object? json,
    List<String> errors,
  ) {
    final root = _Reader.root(json, 'exercises.json', errors);
    if (root == null) return {};
    final result = <String, Exercise>{};
    final list = root.objects('exercises');
    for (final r in list) {
      final id = r.str('id');
      final ex = Exercise(
        id: id,
        name: r.str('name'),
        summary: r.str('summary'),
        kind: r.enumValue('kind', ExerciseKind.values, ExerciseKind.reps),
        sides: r.enumValue('sides', Sides.values, Sides.together),
        equipment: r.enumList('equipment', Equipment.values),
        cues: r.strings('cues', minLength: 1),
        mistakes: r.strings('mistakes', required: false),
        easier: r.strOpt('easier'),
        harder: r.strOpt('harder'),
      );
      if (result.containsKey(id)) {
        errors.add('${r.path}: duplicate exercise id "$id"');
      }
      result[id] = ex;
    }
    return result;
  }

  // ----------------------------------------------------------------- programs

  static Program? _parseProgram(
    Object? json,
    String path,
    List<String> errors,
  ) {
    final r = _Reader.root(json, path, errors);
    if (r == null) return null;

    final pain = r.object('painRules');
    final phases = <Phase>[];
    final phaseReaders = r.objects('phases');
    for (var i = 0; i < phaseReaders.length; i++) {
      phases.add(_parsePhase(phaseReaders[i], i + 1));
    }

    return Program(
      id: r.str('id'),
      name: r.str('name'),
      shortName: r.str('shortName'),
      description: r.str('description'),
      strengthDaysPerWeek: r.integer('strengthDaysPerWeek'),
      painRules: PainRules(
        maxDuring: pain?.integer('maxDuring') ?? 3,
        settleHours: pain?.integer('settleHours') ?? 24,
        morningNoWorse: pain?.boolean('morningNoWorse') ?? true,
      ),
      redFlags: r.strings('redFlags', minLength: 1),
      phases: phases,
      maintenance: r.str('maintenance'),
    );
  }

  static Phase _parsePhase(_Reader r, int number) {
    final sessions = <SessionKind, SessionTemplate>{};
    final s = r.object('sessions');
    if (s != null) {
      for (final kind in SessionKind.values) {
        final sr = s.object(kind.name, required: false);
        if (sr == null) continue;
        sessions[kind] = SessionTemplate(
          kind: kind,
          name: sr.str('name'),
          restSec: sr.integer('restSec'),
          items: [for (final d in sr.objects('items')) _parseDose(d)],
        );
      }
    }

    return Phase(
      id: r.str('id'),
      number: number,
      name: r.str('name'),
      goal: r.str('goal'),
      minDays: r.integer('minDays'),
      cautions: r.strings('cautions', required: false),
      sessions: sessions,
      gate: [for (final g in r.objects('gate')) _parseCriterion(g)],
    );
  }

  static Dose _parseDose(_Reader r) => Dose(
    exerciseId: r.str('ex'),
    sets: r.integer('sets'),
    reps: r.intOpt('reps'),
    repsMax: r.intOpt('repsMax'),
    seconds: r.intOpt('seconds'),
    secondsMax: r.intOpt('secondsMax'),
    restSec: r.intOpt('restSec'),
    note: r.strOpt('note'),
    optional: r.boolOpt('optional') ?? false,
  );

  static GateCriterion _parseCriterion(_Reader r) => GateCriterion(
    id: r.str('id'),
    type: r.enumValue('type', GateType.values, GateType.check),
    text: r.str('text'),
    help: r.strOpt('help'),
    min: r.numOpt('min'),
    unit: r.strOpt('unit'),
    metric: r.has('metric')
        ? r.enumValue('metric', GateMetric.values, GateMetric.painRuleDays)
        : null,
  );

  // --------------------------------------------------------------- validation

  static void _validate(
    Map<String, Exercise> exercises,
    List<Program> programs,
    List<String> errors,
  ) {
    for (final ex in exercises.values) {
      for (final (label, ref) in [
        ('easier', ex.easier),
        ('harder', ex.harder),
      ]) {
        if (ref == null) continue;
        if (ref == ex.id) {
          errors.add('exercise "${ex.id}": $label points to itself');
        } else if (!exercises.containsKey(ref)) {
          errors.add('exercise "${ex.id}": $label "$ref" does not exist');
        }
      }
    }

    final programIds = <String>{};
    for (final p in programs) {
      if (!programIds.add(p.id)) errors.add('duplicate program id "${p.id}"');
      if (p.phases.isEmpty) errors.add('program "${p.id}": has no phases');

      final phaseIds = <String>{};
      for (final ph in p.phases) {
        final where = '${p.id}/${ph.id}';
        if (!phaseIds.add(ph.id)) errors.add('$where: duplicate phase id');
        if (ph.minDays < 1) errors.add('$where: minDays must be at least 1');
        if (ph.sessions.isEmpty) errors.add('$where: has no sessions');
        if (ph.gate.isEmpty) errors.add('$where: has no gate criteria');

        for (final s in ph.sessions.values) {
          if (s.required.isEmpty) {
            errors.add('$where/${s.kind.name}: no required exercises');
          }
          for (final (i, d) in s.items.indexed) {
            _validateDose(d, exercises, '$where/${s.kind.name}[$i]', errors);
          }
        }

        final gateIds = <String>{};
        for (final g in ph.gate) {
          final gw = '$where/gate/${g.id}';
          if (!gateIds.add(g.id)) errors.add('$gw: duplicate criterion id');
          switch (g.type) {
            case GateType.check:
              break;
            case GateType.number:
              if (g.min == null) {
                errors.add('$gw: number criterion needs "min"');
              }
            case GateType.auto:
              if (g.metric == null) {
                errors.add('$gw: auto criterion needs "metric"');
              }
              if (g.min == null) {
                errors.add('$gw: auto criterion needs "min"');
              }
          }
        }
      }
    }
  }

  static void _validateDose(
    Dose d,
    Map<String, Exercise> exercises,
    String where,
    List<String> errors,
  ) {
    final ex = exercises[d.exerciseId];
    if (ex == null) {
      errors.add('$where: exercise "${d.exerciseId}" does not exist');
      return;
    }
    if (d.sets < 1) errors.add('$where: sets must be at least 1');
    if ((d.reps == null) == (d.seconds == null)) {
      errors.add('$where: set exactly one of "reps" or "seconds"');
      return;
    }
    final timedKind = ex.kind != ExerciseKind.reps;
    if (timedKind != d.isTimed) {
      errors.add(
        '$where: "${ex.id}" is a ${ex.kind.name} exercise, so use '
        '${timedKind ? '"seconds"' : '"reps"'}',
      );
    }
    if (d.repsMax != null && (d.reps == null || d.repsMax! < d.reps!)) {
      errors.add('$where: repsMax must be at least reps');
    }
    if (d.secondsMax != null &&
        (d.seconds == null || d.secondsMax! < d.seconds!)) {
      errors.add('$where: secondsMax must be at least seconds');
    }
  }
}

/// Typed access to a JSON object that records errors instead of throwing,
/// returning a harmless fallback so parsing can continue.
class _Reader {
  _Reader(this.map, this.path, this.errors);

  final Map<String, Object?> map;
  final String path;
  final List<String> errors;

  static _Reader? root(Object? json, String path, List<String> errors) {
    if (json is Map<String, Object?>) return _Reader(json, path, errors);
    errors.add('$path: expected an object');
    return null;
  }

  bool has(String key) => map[key] != null;

  T? _get<T>(String key, String expected, {required bool required}) {
    final v = map[key];
    if (v == null) {
      if (required) errors.add('$path.$key: missing ($expected)');
      return null;
    }
    if (v is! T) {
      errors.add('$path.$key: expected $expected, got ${v.runtimeType}');
      return null;
    }
    return v as T;
  }

  String str(String key) => _get<String>(key, 'string', required: true) ?? '';
  String? strOpt(String key) => _get<String>(key, 'string', required: false);

  int integer(String key) => _get<int>(key, 'integer', required: true) ?? 0;
  int? intOpt(String key) => _get<int>(key, 'integer', required: false);
  num? numOpt(String key) => _get<num>(key, 'number', required: false);

  bool boolean(String key) =>
      _get<bool>(key, 'boolean', required: true) ?? false;
  bool? boolOpt(String key) => _get<bool>(key, 'boolean', required: false);

  List<String> strings(String key, {bool required = true, int minLength = 0}) {
    final list = _get<List<Object?>>(
      key,
      'list of strings',
      required: required,
    );
    if (list == null) return const [];
    final out = <String>[];
    for (final (i, v) in list.indexed) {
      if (v is String) {
        out.add(v);
      } else {
        errors.add('$path.$key[$i]: expected string');
      }
    }
    if (out.length < minLength) {
      errors.add('$path.$key: needs at least $minLength item(s)');
    }
    return out;
  }

  T enumValue<T extends Enum>(String key, List<T> values, T fallback) {
    final s = _get<String>(
      key,
      'one of ${values.map((e) => e.name).join('|')}',
      required: true,
    );
    if (s == null) return fallback;
    final v = values.asNameMap()[s];
    if (v == null) {
      errors.add(
        '$path.$key: "$s" is not one of '
        '${values.map((e) => e.name).join(', ')}',
      );
      return fallback;
    }
    return v;
  }

  List<T> enumList<T extends Enum>(String key, List<T> values) {
    final names = values.asNameMap();
    final out = <T>[];
    for (final (i, s) in strings(key, minLength: 1).indexed) {
      final v = names[s];
      if (v != null) {
        out.add(v);
      } else {
        errors.add(
          '$path.$key[$i]: "$s" is not one of '
          '${values.map((e) => e.name).join(', ')}',
        );
      }
    }
    return out;
  }

  _Reader? object(String key, {bool required = true}) {
    final m = _get<Map<String, Object?>>(key, 'object', required: required);
    return m == null ? null : _Reader(m, '$path.$key', errors);
  }

  List<_Reader> objects(String key) {
    final list = _get<List<Object?>>(key, 'list of objects', required: true);
    if (list == null) return const [];
    final out = <_Reader>[];
    for (final (i, v) in list.indexed) {
      final p = '$path.$key[$i]';
      if (v is Map<String, Object?>) {
        // Use the item's id in the path when it has one: easier to find.
        final id = v['id'] ?? v['ex'];
        out.add(_Reader(v, id is String ? '$p($id)' : p, errors));
      } else {
        errors.add('$p: expected object');
      }
    }
    return out;
  }
}
