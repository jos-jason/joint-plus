import 'dart:convert';

/// A time of day, minute precision.
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;

  /// e.g. "08:05".
  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// One reminder: on/off and when.
class ReminderSlot {
  const ReminderSlot({required this.enabled, required this.time});

  final bool enabled;
  final ReminderTime time;

  ReminderSlot copyWith({bool? enabled, ReminderTime? time}) =>
      ReminderSlot(enabled: enabled ?? this.enabled, time: time ?? this.time);

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'hour': time.hour,
    'minute': time.minute,
  };

  static ReminderSlot fromJson(Object? json, ReminderSlot fallback) {
    if (json is! Map) return fallback;
    final h = json['hour'], m = json['minute'], e = json['enabled'];
    if (h is! int || m is! int || e is! bool) return fallback;
    if (h < 0 || h > 23 || m < 0 || m > 59) return fallback;
    return ReminderSlot(enabled: e, time: ReminderTime(h, m));
  }
}

/// All reminder preferences. Everything starts off: turning one on is what
/// asks for notification permission.
class ReminderSettings {
  const ReminderSettings({
    required this.checkIn,
    required this.mobility,
    required this.strength,
    required this.strengthDays,
  });

  static const defaults = ReminderSettings(
    checkIn: ReminderSlot(enabled: false, time: ReminderTime(8, 0)),
    mobility: ReminderSlot(enabled: false, time: ReminderTime(19, 0)),
    strength: ReminderSlot(enabled: false, time: ReminderTime(18, 0)),
    strengthDays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
  );

  /// Morning check-in, every day.
  final ReminderSlot checkIn;

  /// Daily mobility session.
  final ReminderSlot mobility;

  /// Strength session, on [strengthDays].
  final ReminderSlot strength;

  /// Weekdays, `DateTime.monday` (1) … `DateTime.sunday` (7).
  final Set<int> strengthDays;

  bool get anyEnabled =>
      checkIn.enabled ||
      mobility.enabled ||
      (strength.enabled && strengthDays.isNotEmpty);

  /// Two strength days in a row leave no recovery day between them.
  bool get strengthDaysBackToBack => strengthDays.any(
    (d) =>
        strengthDays.contains(d == DateTime.sunday ? DateTime.monday : d + 1),
  );

  ReminderSettings copyWith({
    ReminderSlot? checkIn,
    ReminderSlot? mobility,
    ReminderSlot? strength,
    Set<int>? strengthDays,
  }) => ReminderSettings(
    checkIn: checkIn ?? this.checkIn,
    mobility: mobility ?? this.mobility,
    strength: strength ?? this.strength,
    strengthDays: strengthDays ?? this.strengthDays,
  );

  String encode() => jsonEncode({
    'checkIn': checkIn.toJson(),
    'mobility': mobility.toJson(),
    'strength': strength.toJson(),
    'strengthDays': (strengthDays.toList()..sort()),
  });

  /// Anything missing or malformed falls back to the defaults.
  static ReminderSettings decode(String? source) {
    if (source == null) return defaults;
    Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return defaults;
    }
    if (json is! Map) return defaults;
    final days = json['strengthDays'];
    return ReminderSettings(
      checkIn: ReminderSlot.fromJson(json['checkIn'], defaults.checkIn),
      mobility: ReminderSlot.fromJson(json['mobility'], defaults.mobility),
      strength: ReminderSlot.fromJson(json['strength'], defaults.strength),
      strengthDays: days is List
          ? {
              for (final d in days)
                if (d is int && d >= 1 && d <= 7) d,
            }
          : defaults.strengthDays,
    );
  }
}

/// One repeating notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.route,
    this.weekday,
  });

  /// Stable per slot, so rescheduling replaces rather than duplicates.
  final int id;
  final String title;
  final String body;
  final ReminderTime time;

  /// Screen to open when tapped.
  final String route;

  /// Repeats weekly on this day; null repeats daily.
  final int? weekday;
}

/// Turns settings into the notifications to schedule. Pure, so it's tested
/// without the plugin.
List<PlannedReminder> planReminders(
  ReminderSettings s, {
  required String checkInRoute,
  required String todayRoute,
}) => [
  if (s.checkIn.enabled)
    PlannedReminder(
      id: 1,
      title: 'Morning check-in',
      body: 'Pain, swelling, stiffness: 3 taps before you get going.',
      time: s.checkIn.time,
      route: checkInRoute,
    ),
  if (s.mobility.enabled)
    PlannedReminder(
      id: 2,
      title: 'Mobility',
      body: 'About 10 minutes to keep the knee moving.',
      time: s.mobility.time,
      route: todayRoute,
    ),
  if (s.strength.enabled)
    for (final d in s.strengthDays.toList()..sort())
      PlannedReminder(
        id: 10 + d,
        title: 'Strength day',
        body: 'Your strength session is today. About 30 minutes.',
        time: s.strength.time,
        route: todayRoute,
        weekday: d,
      ),
];
