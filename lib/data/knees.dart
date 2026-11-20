import 'dart:convert';

enum Knee { left, right }

extension KneeX on Knee {
  String get label => this == Knee.left ? 'Left' : 'Right';
  Knee get other => this == Knee.left ? Knee.right : Knee.left;
}

/// Check-in key used when only one knee is in rehab, or none is set yet.
const singleKneeKey = 'knee';

/// Which knees are in rehab and, with both, which one goes first.
/// Saved in app settings; null until chosen, when the app speaks of "the
/// injured leg" as it always did.
class KneeSetup {
  KneeSetup.one(Knee knee) : knees = {knee}, first = knee;
  const KneeSetup.both({this.first = Knee.left})
    : knees = const {Knee.left, Knee.right};

  final Set<Knee> knees;

  /// With both knees: the one each exercise starts on.
  final Knee first;

  bool get both => knees.length == 2;

  /// Order for one-leg exercises done on each leg.
  List<Knee> get eachOrder => [first, first.other];

  /// Order for exercises meant for the recovering knee only.
  List<Knee> get recoveringOrder => both ? [first, first.other] : [first];

  /// One morning check-in row per key.
  List<String> get checkInKeys =>
      both ? [first.name, first.other.name] : const [singleKneeKey];

  /// e.g. "Both knees, left first" or "Right knee".
  String get label => both
      ? 'Both knees, ${first.label.toLowerCase()} first'
      : '${first.label} knee';

  String encode() => jsonEncode({
    'knees': [for (final k in knees) k.name]..sort(),
    'first': first.name,
  });

  /// Null for anything missing or malformed.
  static KneeSetup? decode(String? source) {
    if (source == null) return null;
    try {
      final json = jsonDecode(source);
      if (json is! Map) return null;
      final names = (json['knees'] as List?)?.whereType<String>().toSet() ?? {};
      final knees = {for (final n in names) ?Knee.values.asNameMap()[n]};
      final first = Knee.values.asNameMap()[json['first']];
      if (knees.length == 2) return KneeSetup.both(first: first ?? Knee.left);
      if (knees.length == 1) return KneeSetup.one(knees.single);
      return null;
    } on FormatException {
      return null;
    }
  }
}

/// How a check-in key reads on screen: "Left knee", or "Knee" for one knee.
String checkInKeyLabel(String key) => switch (key) {
  'left' => 'Left knee',
  'right' => 'Right knee',
  _ => 'Knee',
};
