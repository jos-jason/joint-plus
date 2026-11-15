import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/reminder_providers.dart';
import '../../reminders/reminder_settings.dart';
import '../../theme/tokens.dart';
import '../../widgets/stark_primitives.dart';
import '../../widgets/stark_switch.dart';

/// Reminder toggles and times. Changes save and reschedule immediately.
class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s =
        ref.watch(reminderSettingsProvider).value ?? ReminderSettings.defaults;

    Future<void> save(ReminderSettings next) async {
      final ok = await ref.read(reminderControllerProvider).update(next);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are off for Joint+. Turn them on in your '
              "phone's Settings.",
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            JSpace.gutter,
            JSpace.lg,
            JSpace.gutter,
            JSpace.sm,
          ),
          child: SectionLabel('Reminders'),
        ),
        const Hairline(),
        _SlotRow(
          title: 'Morning check-in',
          detail: 'Every day',
          slot: s.checkIn,
          onChanged: (v) => save(s.copyWith(checkIn: v)),
        ),
        _SlotRow(
          title: 'Mobility',
          detail: 'Every day',
          slot: s.mobility,
          onChanged: (v) => save(s.copyWith(mobility: v)),
        ),
        _SlotRow(
          title: 'Strength',
          detail: s.strengthDays.isEmpty
              ? 'No days picked'
              : '${s.strengthDays.length}× a week',
          slot: s.strength,
          onChanged: (v) => save(s.copyWith(strength: v)),
          below: Padding(
            padding: const EdgeInsets.fromLTRB(
              JSpace.gutter,
              0,
              JSpace.gutter,
              JSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DayCells(
                  days: s.strengthDays,
                  onChanged: (days) => save(s.copyWith(strengthDays: days)),
                ),
                if (s.strengthDaysBackToBack) ...[
                  const SizedBox(height: JSpace.sm),
                  const Text(
                    'Leave a rest day between strength days so the knee '
                    'can recover.',
                    style: JType.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.title,
    required this.detail,
    required this.slot,
    required this.onChanged,
    this.below,
  });

  final String title;
  final String detail;
  final ReminderSlot slot;
  final ValueChanged<ReminderSlot> onChanged;
  final Widget? below;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: slot.time.hour, minute: slot.time.minute),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: JColors.green,
              onPrimary: JColors.black,
              surface: JColors.black,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked == null) return;
    onChanged(slot.copyWith(time: ReminderTime(picked.hour, picked.minute)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: JSpace.gutter, right: JSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Change $title time, now ${slot.time.label}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickTime(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: JSpace.md + 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: JType.body),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: slot.time.label,
                                  style: JType.number.copyWith(
                                    fontSize: 14,
                                    color: slot.enabled
                                        ? JColors.white
                                        : JColors.grey,
                                  ),
                                ),
                                TextSpan(text: '  ·  $detail'),
                              ],
                            ),
                            style: JType.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              StarkSwitch(
                value: slot.enabled,
                semanticLabel: '$title reminder',
                onChanged: (v) => onChanged(slot.copyWith(enabled: v)),
              ),
            ],
          ),
        ),
        ?below,
        const Hairline(),
      ],
    );
  }
}

/// Seven toggle cells, Monday first.
class _DayCells extends StatelessWidget {
  const _DayCells({required this.days, required this.onChanged});

  final Set<int> days;
  final ValueChanged<Set<int>> onChanged;

  static const _short = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _long = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var d = 1; d <= 7; d++)
          Expanded(
            child: Semantics(
              button: true,
              selected: days.contains(d),
              label: 'Strength on ${_long[d - 1]}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(
                  days.contains(d) ? ({...days}..remove(d)) : {...days, d},
                ),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: days.contains(d)
                        ? JColors.green
                        : Colors.transparent,
                    border: Border(
                      top: const BorderSide(color: JColors.line),
                      bottom: const BorderSide(color: JColors.line),
                      left: d == 1
                          ? const BorderSide(color: JColors.line)
                          : BorderSide.none,
                      right: const BorderSide(color: JColors.line),
                    ),
                  ),
                  child: Text(
                    _short[d - 1],
                    style: JType.label.copyWith(
                      color: days.contains(d) ? JColors.black : JColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
