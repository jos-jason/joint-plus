import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joint_plus/app/app.dart';
import 'package:joint_plus/content/content_loader.dart';
import 'package:joint_plus/content/content_providers.dart';
import 'package:joint_plus/content/models.dart';
import 'package:joint_plus/data/data_providers.dart';
import 'package:joint_plus/data/database.dart';
import 'package:joint_plus/reminders/reminder_providers.dart';
import 'package:joint_plus/reminders/reminder_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Asset loading is real I/O, which widget tests' fake clock can't wait on.
  // Load once outside the fake zone and hand the result to the app.
  late ContentLibrary content;
  setUpAll(() async => content = await ContentLoader(rootBundle).load());

  /// Pumps the app on a phone-sized screen (iPhone 17 Pro, 402 × 874 pt),
  /// with an empty in-memory database that [seed] can fill first.
  Future<AppDatabase> pumpApp(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? seed,
    ReminderScheduler? reminders,
  }) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    if (seed != null) await seed(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) => content),
          databaseProvider.overrideWithValue(db),
          reminderSchedulerProvider.overrideWithValue(
            reminders ?? NoReminders(),
          ),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 14, 8)),
        ],
        child: const JointPlusApp(),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  /// Longer than the player's double-tap guard.
  const settle = Duration(milliseconds: 500);

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Today shows the phase and the strength session exercises', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('START SESSION'), findsOneWidget);
    expect(find.text('Calm & Activate'), findsOneWidget);
    expect(find.text('Shallow Wall Sit'), findsOneWidget);
    expect(find.text('5 × 30–45 s'), findsOneWidget);
  });

  testWidgets('Today switches to the mobility session', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('MOBILITY'));
    await tester.pumpAndSettle();
    expect(find.text('Mobility'), findsOneWidget); // header title
    await scrollTo(tester, find.text('Heel Slide'));
    expect(find.text('Heel Slide'), findsOneWidget);
  });

  testWidgets('exercise detail shows dose and cues, and links to swaps', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Shallow Wall Sit'));
    await tester.pumpAndSettle();
    expect(find.text('5 × 30–45 s'), findsOneWidget);
    expect(find.text('Rest 60 s between sets'), findsOneWidget);
    expect(find.text('HOW TO'), findsOneWidget);
    expect(find.bySemanticsLabel('Drawing of Shallow Wall Sit'), findsOneWidget);

    await scrollTo(tester, find.text('Spanish Squat'));
    await tester.tap(find.text('Spanish Squat'));
    await tester.pumpAndSettle();
    // Opened as a swap: same layout, but no session dose.
    expect(find.text('Spanish Squat'), findsOneWidget);
    expect(find.textContaining('Rest '), findsNothing);
  });

  testWidgets('Program opens a phase with its sessions and checks', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('PROGRAM'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('STOP AND CONTACT YOUR CLINICIAN IF'));
    expect(find.text('—  The knee gives way'), findsOneWidget);

    await scrollTo(tester, find.text('Build Strength'));
    await tester.tap(find.text('Build Strength'));
    await tester.pumpAndSettle();
    expect(find.text('Assisted Squat to 90°'), findsOneWidget);
    await scrollTo(tester, find.text('CHECKS TO MOVE ON'));
    await scrollTo(
      tester,
      find.text('Step-ups 3×10 with no reaction the next morning'),
    );
  });

  testWidgets('History tab and settings preview still work', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(find.text('No sessions yet'), findsOneWidget);

    await tester.tap(find.text('TODAY'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Components'));
    await tester.pumpAndSettle();
    expect(find.text('TIMER RING'), findsOneWidget);
  });

  testWidgets('session player runs pain check, timed hold, rest and summary', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('START SESSION'));
    await tester.pumpAndSettle();
    expect(find.text('How does the knee feel right now?'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    await tester.pump(settle);

    // Shallow Wall Sit: 5 × 30–45 s hold.
    expect(find.text('Shallow Wall Sit'), findsOneWidget);
    expect(find.text('SET 1 OF 5'), findsOneWidget);
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('30'), findsOneWidget);
    expect(find.text('TARGET REACHED · UP TO 45 S'), findsOneWidget);
    await tester.tap(find.text('DONE'));
    await tester.pump();
    // A quick second tap is ignored while the rest screen settles in.
    await tester.tap(find.text('SKIP REST'));
    await tester.pump();
    expect(find.text('REST'), findsOneWidget);
    await tester.pump(settle);

    expect(find.text('REST'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60)); // rest runs out by itself
    expect(find.text('SET 2 OF 5'), findsOneWidget);

    // Skip the rest of the session.
    while (find.text('SKIP').evaluate().isNotEmpty) {
      await tester.tap(find.text('SKIP'));
      await tester.pump(settle);
    }
    expect(
      find.text('What was the worst pain during the session?'),
      findsOneWidget,
    );
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.textContaining('Above 3/10'), findsOneWidget);
    await tester.tap(find.text('FINISH'));
    await tester.pump(settle);

    expect(find.text('Done.'), findsOneWidget);
    expect(find.text('2 → 5'), findsOneWidget);
    expect(find.text('0 / 6'), findsOneWidget); // exercises completed
    expect(find.text('1 / 20'), findsOneWidget); // sets
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.text('START SESSION'), findsOneWidget);

    // The session was logged.
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(find.text('1 session'), findsOneWidget);
    expect(find.text('Strength  ·  Sat 14 Nov'), findsOneWidget);
    expect(find.textContaining('0/6 exercises'), findsOneWidget);
    expect(find.bySemanticsLabel('Sat 14 Nov, session done'), findsOneWidget);
  });

  testWidgets('morning check-in saves and shows on Today', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Morning check-in'));
    await tester.pumpAndSettle();
    expect(find.text('SAVE'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.tap(find.bySemanticsLabel('Swelling Less'));
    await tester.pump();
    expect(find.textContaining('Worse than yesterday'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Stiffness More'));
    await tester.pump();
    expect(find.textContaining('Worse than yesterday'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Stiffness Same'));
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    expect(find.text('START SESSION'), findsOneWidget);
    expect(
      find.text('Pain 1  ·  swelling less  ·  stiffness same'),
      findsOneWidget,
    );

    // Reopening edits today's entry, starting from what was saved.
    await tester.tap(find.text('Morning check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pain 4  ·  swelling less  ·  stiffness same'),
      findsOneWidget,
    );
  });

  testWidgets('leaving a started session asks first', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('START SESSION'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('End session?'), findsOneWidget);
    await tester.tap(find.text('KEEP GOING'));
    await tester.pumpAndSettle();
    expect(find.text('Shallow Wall Sit'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('END SESSION'));
    await tester.pumpAndSettle();
    expect(find.text('START SESSION'), findsOneWidget);
  });

  group('progression', () {
    Future<void> enter(AppDatabase db, String phaseId) => db.addPhaseEvent(
      programId: 'knee_meniscus',
      phaseId: phaseId,
      kind: PhaseEventKind.entry,
      at: DateTime(2026, 11, 1, 9),
    );

    testWidgets('entry check suggests Phase 2 when every answer is yes', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('START HERE'), findsOneWidget);
      await tester.tap(find.textContaining('entry check'));
      await tester.pumpAndSettle();
      expect(find.text('ANSWER ALL 4'), findsOneWidget);

      for (var i = 0; i < 4; i++) {
        final yes = find.text('YES').at(i);
        await tester.ensureVisible(yes);
        await tester.pumpAndSettle();
        await tester.tap(yes);
        await tester.pump();
      }
      expect(find.text('SUGGESTED: PHASE 2'), findsOneWidget);
      await tester.tap(find.text('START BUILD STRENGTH'));
      await tester.pumpAndSettle();

      expect(find.text('START HERE'), findsNothing);
      expect(find.text('Build Strength'), findsOneWidget);
      expect(find.textContaining('Phase 2 of 4  ·  day 1'), findsOneWidget);
    });

    testWidgets('passing every check unlocks the next phase', (tester) async {
      await pumpApp(
        tester,
        seed: (db) async {
          await enter(db, 'p1');
          for (var d = 7; d <= 13; d++) {
            await db.saveCheckIn(
              at: DateTime(2026, 11, d, 7),
              pain: 2,
              swelling: Change.same,
              stiffness: Change.less,
            );
          }
          for (final id in ['full_extension', 'slr_no_lag']) {
            await db.saveGateResult(
              programId: 'knee_meniscus',
              phaseId: 'p1',
              criterionId: id,
              passed: true,
              at: DateTime(2026, 11, 10),
            );
          }
        },
      );

      expect(find.textContaining('3/4 checks'), findsOneWidget);
      await tester.tap(find.text('Calm & Activate'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('MOVE TO PHASE 2'));

      // The balance test is the last one missing: 24 s isn't enough, 32 s is.
      Future<void> measure(String seconds) async {
        await tester.tap(find.text('Single-leg balance on the injured leg'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), seconds);
        await tester.pump();
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();
      }

      await measure('24');
      expect(find.textContaining('24 s'), findsOneWidget);
      await tester.tap(find.text('MOVE TO PHASE 2'));
      await tester.pumpAndSettle();
      expect(find.text('Move to Build Strength?'), findsNothing); // disabled

      await measure('32');
      expect(find.text('CHECKS TO MOVE ON  ·  4/4'), findsOneWidget);
      await tester.tap(find.text('MOVE TO PHASE 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MOVE ON'));
      await tester.pumpAndSettle();

      expect(find.text('Build Strength'), findsOneWidget);
      expect(find.textContaining('0/4 checks'), findsOneWidget);
    });

    testWidgets('two flare-up mornings in a row suggest dropping back', (
      tester,
    ) async {
      await pumpApp(
        tester,
        seed: (db) async {
          await enter(db, 'p2');
          await db.saveCheckIn(
            at: DateTime(2026, 11, 13, 7),
            pain: 2,
            swelling: Change.more,
            stiffness: Change.same,
          );
          await db.saveCheckIn(
            at: DateTime(2026, 11, 14, 7),
            pain: 2,
            swelling: Change.same,
            stiffness: Change.more,
          );
        },
      );

      expect(find.text('FLARE-UP'), findsOneWidget);
      expect(
        find.textContaining('More stiffness this morning'),
        findsOneWidget,
      );
      await tester.tap(find.text('FLARE-UP'));
      await tester.pumpAndSettle();
      expect(find.text('Drop back to Phase 1?'), findsOneWidget);
      await tester.tap(find.text('DROP BACK'));
      await tester.pumpAndSettle();

      expect(find.text('Calm & Activate'), findsOneWidget);
      // The new stint starts today, so yesterday's flare no longer counts:
      // only this morning's broken day remains → repeat the dose.
      expect(find.text('REPEAT THIS DOSE'), findsOneWidget);
    });
  });

  group('reminders', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
    }

    testWidgets('turning reminders on schedules them', (tester) async {
      final reminders = NoReminders();
      await pumpApp(tester, reminders: reminders);
      await openSettings(tester);

      await tester.tap(find.bySemanticsLabel('Morning check-in reminder'));
      await tester.pumpAndSettle();
      expect(reminders.applied.map((r) => (r.id, r.route)), [(1, '/checkin')]);

      await tester.tap(find.bySemanticsLabel('Strength reminder'));
      await tester.pumpAndSettle();
      expect(reminders.applied.map((r) => r.weekday), [null, 1, 3, 5]);

      // Thursday next to Wednesday/Friday: no rest day.
      await tester.tap(find.bySemanticsLabel('Strength on Thursday'));
      await tester.pumpAndSettle();
      expect(reminders.applied.map((r) => r.weekday), [null, 1, 3, 4, 5]);
      expect(find.textContaining('Leave a rest day'), findsOneWidget);
      expect(find.textContaining('4× a week'), findsOneWidget);
    });

    testWidgets('refused permission leaves reminders off', (tester) async {
      final reminders = NoReminders()..permission = false;
      await pumpApp(tester, reminders: reminders);
      await openSettings(tester);

      await tester.tap(find.bySemanticsLabel('Mobility reminder'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Notifications are off'), findsOneWidget);
      expect(reminders.applied, isEmpty);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Mobility reminder')),
        matchesSemantics(
          label: 'Mobility reminder',
          isToggled: false,
          hasToggledState: true,
        ),
      );
    });
  });

  testWidgets('History shows the pain trend and phase milestones', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await db.addPhaseEvent(
          programId: 'knee_meniscus',
          phaseId: 'p1',
          kind: PhaseEventKind.entry,
          at: DateTime(2026, 11, 1, 9),
        );
        await db.addPhaseEvent(
          programId: 'knee_meniscus',
          phaseId: 'p2',
          kind: PhaseEventKind.advance,
          at: DateTime(2026, 11, 10, 9),
        );
        for (final (d, pain) in [(11, 3), (12, 2), (13, 2)]) {
          await db.saveCheckIn(
            at: DateTime(2026, 11, d, 7),
            pain: pain,
            swelling: Change.same,
            stiffness: Change.same,
          );
        }
      },
    );

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(find.text('PAIN TREND'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('latest 2, highest 3 out of 10')),
      findsOneWidget,
    );
    await scrollTo(tester, find.text('Started at Phase 1'));
    expect(find.text('Moved up to Phase 2'), findsOneWidget);
    expect(find.text('Build Strength  ·  Tue 10 Nov'), findsOneWidget);
  });
}
