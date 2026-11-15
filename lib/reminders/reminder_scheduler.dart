import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_settings.dart';

/// Schedules repeating local notifications. An interface so tests (and
/// platforms without notifications) can swap in [NoReminders].
abstract class ReminderScheduler {
  /// Sets up the plugin. [onOpen] receives the route of a tapped reminder,
  /// including the one that launched the app.
  Future<void> init({required void Function(String route) onOpen});

  /// Asks the OS for permission. True when reminders can be shown.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with [plan].
  Future<void> apply(List<PlannedReminder> plan);
}

/// Does nothing; remembers the last plan for tests.
class NoReminders implements ReminderScheduler {
  List<PlannedReminder> applied = const [];
  bool permission = true;

  @override
  Future<void> init({required void Function(String route) onOpen}) async {}

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> apply(List<PlannedReminder> plan) async => applied = plan;
}

/// iOS and Android notifications via flutter_local_notifications.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Check-in and session reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init({required void Function(String route) onOpen}) =>
      _ready ??= _init(onOpen);

  Future<void> _init(void Function(String route) onOpen) async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Unknown zone name: fall back to UTC rather than not scheduling at all.
      debugPrint('Reminders: local time zone unavailable ($e), using UTC');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked when a reminder is first turned on, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload case final route? when route.isNotEmpty) onOpen(route);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    final route = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) &&
        route != null &&
        route.isNotEmpty) {
      onOpen(route);
    }
  }

  @override
  Future<bool> requestPermission() async {
    await _ready;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  @override
  Future<void> apply(List<PlannedReminder> plan) async {
    await _ready;
    await _plugin.cancelAll();
    for (final r in plan) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        payload: r.route,
        scheduledDate: nextOccurrence(tz.TZDateTime.now(tz.local), r),
        notificationDetails: _details,
        // Inexact needs no special alarm permission; a few minutes' drift is
        // fine for a reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: r.weekday == null
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
}

/// The first time strictly after [now] that [r] should fire.
tz.TZDateTime nextOccurrence(tz.TZDateTime now, PlannedReminder r) {
  var t = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    r.time.hour,
    r.time.minute,
  );
  if (r.weekday != null) {
    t = t.add(Duration(days: (r.weekday! - t.weekday) % 7));
  }
  if (!t.isAfter(now)) t = t.add(Duration(days: r.weekday == null ? 1 : 7));
  return t;
}
