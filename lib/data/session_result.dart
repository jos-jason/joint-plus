import '../content/models.dart';

/// What happened to one exercise in a finished session.
class ItemResult {
  const ItemResult({
    required this.exerciseId,
    required this.setsPlanned,
    required this.setsDone,
    required this.optional,
  });

  final String exerciseId;
  final int setsPlanned;
  final int setsDone;
  final bool optional;

  bool get complete => setsDone >= setsPlanned;
}

/// A finished session, as the player reports it and the log stores it.
class SessionResult {
  const SessionResult({
    required this.kind,
    required this.startedAt,
    required this.endedAt,
    required this.painBefore,
    required this.painAfter,
    required this.items,
  });

  final SessionKind kind;
  final DateTime startedAt;
  final DateTime endedAt;
  final int painBefore;
  final int painAfter;
  final List<ItemResult> items;
}
