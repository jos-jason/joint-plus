import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/reminders/reminder_scheduler.dart';
import 'package:joint_plus/reminders/reminder_settings.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  const on = ReminderSettings(
    checkIn: ReminderSlot(enabled: true, time: ReminderTime(7, 30)),
    mobility: ReminderSlot(enabled: false, time: ReminderTime(19, 0)),
    strength: ReminderSlot(enabled: true, time: ReminderTime(18, 5)),
    strengthDays: {DateTime.friday, DateTime.monday},
  );

  test('settings survive a save/load round trip', () {
    final back = ReminderSettings.decode(on.encode());
    expect(back.checkIn.enabled, isTrue);
    expect(back.checkIn.time, const ReminderTime(7, 30));
    expect(back.mobility.enabled, isFalse);
    expect(back.strength.time.label, '18:05');
    expect(back.strengthDays, {1, 5});
  });

  test('missing or malformed settings fall back to the defaults', () {
    for (final bad in [null, 'not json', '[]', '{"checkIn": {"hour": 99}}']) {
      final s = ReminderSettings.decode(bad);
      expect(s.checkIn.time, ReminderSettings.defaults.checkIn.time);
      expect(s.anyEnabled, isFalse);
    }
    expect(
      ReminderSettings.decode('{"strengthDays": [0, 3, 9, "x"]}').strengthDays,
      {3},
    );
  });

  test('plans one daily reminder per slot and one weekly per strength day', () {
    final plan = planReminders(on, checkInRoute: '/checkin', todayRoute: '/');
    expect(
      [for (final r in plan) (r.id, r.weekday, r.route)],
      [
        (1, null, '/checkin'),
        (11, DateTime.monday, '/'),
        (15, DateTime.friday, '/'),
      ],
    );
    expect(
      planReminders(
        on.copyWith(strength: on.strength.copyWith(enabled: false)),
        checkInRoute: '/checkin',
        todayRoute: '/',
      ),
      hasLength(1),
    );
  });

  test('flags strength days with no rest day between them', () {
    expect(on.strengthDaysBackToBack, isFalse);
    expect(on.copyWith(strengthDays: {1, 2}).strengthDaysBackToBack, isTrue);
    // Sunday → Monday wraps around the week.
    expect(on.copyWith(strengthDays: {7, 1}).strengthDaysBackToBack, isTrue);
  });

  group('next occurrence', () {
    setUpAll(tzdata.initializeTimeZones);

    PlannedReminder at(int h, int m, {int? weekday}) => PlannedReminder(
      id: 1,
      title: '',
      body: '',
      time: ReminderTime(h, m),
      route: '/',
      weekday: weekday,
    );

    test('daily: later today, else tomorrow', () {
      final london = tz.getLocation('Europe/London');
      final now = tz.TZDateTime(london, 2026, 11, 14, 8); // Saturday 08:00
      expect(
        nextOccurrence(now, at(9, 0)),
        tz.TZDateTime(london, 2026, 11, 14, 9),
      );
      expect(
        nextOccurrence(now, at(8, 0)),
        tz.TZDateTime(london, 2026, 11, 15, 8),
      );
    });

    test('weekly: the next matching weekday', () {
      final london = tz.getLocation('Europe/London');
      final now = tz.TZDateTime(london, 2026, 11, 14, 8); // Saturday
      expect(
        nextOccurrence(now, at(18, 0, weekday: DateTime.monday)),
        tz.TZDateTime(london, 2026, 11, 16, 18),
      );
      expect(
        nextOccurrence(now, at(7, 0, weekday: DateTime.saturday)),
        tz.TZDateTime(london, 2026, 11, 21, 7),
      );
    });
  });
}
