import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../data/data_providers.dart';
import 'reminder_scheduler.dart';
import 'reminder_settings.dart';

const _key = 'reminders';

/// The platform notification scheduler. Tests override it with [NoReminders].
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalReminderScheduler(),
);

/// Saved reminder preferences (defaults until something is saved).
final reminderSettingsProvider = StreamProvider<ReminderSettings>(
  (ref) => ref
      .watch(databaseProvider)
      .watchSetting(_key)
      .map(ReminderSettings.decode),
);

List<PlannedReminder> _plan(ReminderSettings s) =>
    planReminders(s, checkInRoute: Routes.checkIn, todayRoute: Routes.today);

class ReminderController {
  ReminderController(this._ref);

  final Ref _ref;

  ReminderScheduler get _scheduler => _ref.read(reminderSchedulerProvider);

  /// Saves and reschedules. When this turns reminders on, asks for permission
  /// first; returns false (and saves nothing) if it was refused.
  Future<bool> update(ReminderSettings next) async {
    final current =
        _ref.read(reminderSettingsProvider).value ?? ReminderSettings.defaults;
    if (next.anyEnabled &&
        !current.anyEnabled &&
        !await _scheduler.requestPermission()) {
      return false;
    }
    await _ref.read(databaseProvider).putSetting(_key, next.encode());
    await _scheduler.apply(_plan(next));
    return true;
  }

  /// At launch: set up the plugin and re-apply the saved plan, so changes of
  /// time zone or a reinstall don't leave reminders stale.
  Future<void> start({required void Function(String route) onOpen}) async {
    await _scheduler.init(onOpen: onOpen);
    final saved = await _ref.read(databaseProvider).watchSetting(_key).first;
    final settings = ReminderSettings.decode(saved);
    if (settings.anyEnabled) await _scheduler.apply(_plan(settings));
  }
}

final reminderControllerProvider = Provider(ReminderController.new);
