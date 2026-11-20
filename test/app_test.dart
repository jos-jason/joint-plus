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
import 'package:joint_plus/data/knees.dart';
import 'package:joint_plus/data/session_result.dart';
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
    DateTime? now,
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
          clockProvider.overrideWithValue(
            () => now ?? DateTime(2026, 11, 14, 8), // a Saturday
          ),
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

  /// Today's STRENGTH / MOBILITY tabs sit below the day checklist.
  Future<void> tapTab(WidgetTester tester, String tab) async {
    await scrollTo(tester, find.text(tab));
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }

  testWidgets('a rest day shows mobility first, strength as optional', (
    tester,
  ) async {
    await pumpApp(tester); // Saturday; strength days default to Mon/Wed/Fri

    expect(find.text('Mobility day'), findsOneWidget);
    expect(
      find.text('Mobility only today. Next strength day: Mon 16 Nov.'),
      findsOneWidget,
    );
    expect(find.text('Rest day  ·  next Mon 16 Nov'), findsOneWidget);
    expect(find.text('START MOBILITY'), findsOneWidget);
    await scrollTo(tester, find.text('Heel Slide'));

    // Strength is still there to do as an extra.
    await tapTab(tester, 'STRENGTH');
    await scrollTo(tester, find.text('Shallow Wall Sit'));
    expect(find.text('5 × 30–45 s'), findsOneWidget);
    expect(find.text('START STRENGTH ANYWAY'), findsOneWidget);
  });

  testWidgets('a strength day lists both and ticks off what is done', (
    tester,
  ) async {
    final monday = DateTime(2026, 11, 16, 9);
    await pumpApp(
      tester,
      now: monday,
      seed: (db) => db.saveSession(
        programId: 'knee_meniscus',
        phaseId: 'p1',
        result: SessionResult(
          kind: SessionKind.daily,
          startedAt: DateTime(2026, 11, 16, 7),
          endedAt: DateTime(2026, 11, 16, 7, 10),
          painBefore: 1,
          painAfter: 1,
          items: const [
            ItemResult(
              exerciseId: 'heel_slide',
              setsPlanned: 2,
              setsDone: 2,
              optional: false,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Strength day'), findsOneWidget);
    expect(find.text('Mobility and strength today.'), findsOneWidget);
    expect(find.text('Done  ·  1/1 exercises'), findsOneWidget); // mobility
    expect(find.textContaining('due today'), findsOneWidget); // strength
    // Opens on what's still to do.
    expect(find.text('START STRENGTH'), findsOneWidget);
    await tapTab(tester, 'MOBILITY');
    expect(find.text('DO MOBILITY AGAIN'), findsOneWidget);
  });

  testWidgets('exercise detail shows dose and cues, and links to swaps', (
    tester,
  ) async {
    await pumpApp(tester);

    await tapTab(tester, 'STRENGTH');
    await scrollTo(tester, find.text('Shallow Wall Sit'));
    await tester.tap(find.text('Shallow Wall Sit'));
    await tester.pumpAndSettle();
    expect(find.text('5 × 30–45 s'), findsOneWidget);
    expect(find.text('Rest 120 s between sets'), findsOneWidget);
    expect(find.text('HOW TO'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Drawing of Shallow Wall Sit'),
      findsOneWidget,
    );

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
    await scrollTo(tester, find.text('Components'));
    await tester.tap(find.text('Components'));
    await tester.pumpAndSettle();
    expect(find.text('TIMER RING'), findsOneWidget);
  });

  /// Opens the strength session and gets past the opening pain check.
  /// From here timers run, so tests pump fixed durations, not pumpAndSettle.
  Future<void> startSession(WidgetTester tester, {String pain = '2'}) async {
    // Saturday is a rest day, so strength starts as an extra.
    await tapTab(tester, 'STRENGTH');
    await tester.tap(find.text('START STRENGTH ANYWAY'));
    await tester.pumpAndSettle();
    expect(find.text('How does the knee feel right now?'), findsOneWidget);
    await tester.tap(find.text(pain));
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pump(settle);
  }

  testWidgets('session flows on its own: up next, get ready, hold, rest', (
    tester,
  ) async {
    await pumpApp(tester);
    await startSession(tester);

    // "Up next" shows the exercise and dose, then moves on by itself.
    expect(find.text('UP NEXT · 1 / 6'), findsOneWidget);
    expect(find.text('Shallow Wall Sit'), findsOneWidget);
    expect(find.text('5 × 30–45 s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));

    // Each set starts with a 3-2-1, then the hold clock runs.
    expect(find.text('SET 1 OF 5'), findsOneWidget);
    expect(find.text('GET READY'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('30'), findsOneWidget);
    expect(find.text('TARGET REACHED · UP TO 45 S'), findsOneWidget);

    // Tapping the ring pauses the clock, and again resumes it.
    await tester.tap(find.bySemanticsLabel(RegExp('^Pause timer')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('30'), findsOneWidget);
    expect(find.text('PAUSED · TAP TO RESUME'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Resume timer')));
    await tester.pump();

    await tester.tap(find.text('DONE'));
    await tester.pump();
    // A quick second tap is ignored while the rest screen settles in.
    await tester.tap(find.text('SKIP REST'));
    await tester.pump();
    expect(find.text('REST'), findsOneWidget);
    await tester.pump(settle);

    // +15 s stretches the rest; then it runs into the next set by itself.
    await tester.tap(find.text('+15 S'));
    await tester.pump();
    // Wall-sit rests are 120 s (tendon-friendly isometrics), plus the 15.
    await tester.pump(const Duration(seconds: 120));
    expect(find.text('REST'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
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
    expect(find.text('DO STRENGTH AGAIN'), findsOneWidget); // strength done

    // The session was logged.
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(find.text('1 session'), findsOneWidget);
    expect(find.text('Sat 14 Nov'), findsOneWidget); // day heading
    expect(find.text('Strength'), findsWidgets);
    expect(find.textContaining('0/6 exercises'), findsOneWidget);
    expect(find.bySemanticsLabel('Sat 14 Nov, strength'), findsOneWidget);
  });

  testWidgets('reps count themselves at the exercise pace', (tester) async {
    await pumpApp(tester);
    await startSession(tester);

    // Skip the wall sit from its "up next" screen; start the band TKE now.
    await tester.tap(find.text('SKIP'));
    await tester.pump(settle);
    expect(find.text('Terminal Knee Extension'), findsOneWidget);
    await tester.tap(find.text('START NOW'));
    await tester.pump(settle);
    await tester.pump(const Duration(seconds: 3)); // get ready

    // 1 rep every 4 s: five reps after 20 s.
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('5'), findsOneWidget);
    expect(find.text('OF 15 REPS'), findsOneWidget);
    expect(find.text('1 rep every 4 s'), findsOneWidget);

    // At 15 the set finishes by itself and the rest starts.
    await tester.pump(const Duration(seconds: 40));
    expect(find.text('REST'), findsOneWidget);
  });

  testWidgets('one-leg sets get a short switch between sides', (tester) async {
    await pumpApp(tester);
    await startSession(tester);

    // Skip ahead to the clamshell (each leg).
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('SKIP'));
      await tester.pump(settle);
    }
    expect(find.text('Clamshell'), findsOneWidget);
    await tester.tap(find.text('START NOW'));
    await tester.pump(settle);
    expect(find.text('SET 1 OF 3  ·  INJURED LEG'), findsOneWidget);
    await tester.tap(find.text('DONE'));
    await tester.pump(settle);
    expect(find.text('SWITCH LEGS'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('SET 1 OF 3  ·  OTHER LEG'), findsOneWidget);
  });

  testWidgets('morning check-in saves and shows on Today', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Morning check-in'));
    await tester.pumpAndSettle();
    expect(find.text('SAVE'), findsOneWidget);
    expect(find.textContaining('TENDON TEST'), findsOneWidget);
    await tester.tap(find.text('1').first);
    await tester.tap(find.bySemanticsLabel('Swelling Less'));
    await tester.pump();
    expect(find.textContaining('Worse than yesterday'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Stiffness More'));
    await tester.pump();
    await scrollTo(tester, find.textContaining('Worse than yesterday'));
    expect(find.textContaining('Worse than yesterday'), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel('Stiffness Same'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Stiffness Same'));
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    expect(find.text('Mobility day'), findsOneWidget);
    expect(
      find.text('Pain 1  ·  swelling less  ·  stiffness same'),
      findsOneWidget,
    );

    // Reopening edits today's entry, starting from what was saved.
    await tester.tap(find.text('Morning check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').first);
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pain 4  ·  swelling less  ·  stiffness same'),
      findsOneWidget,
    );
  });

  testWidgets('leaving a started session asks first', (tester) async {
    await pumpApp(tester);
    await startSession(tester, pain: '0');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle(); // the clock pauses while the dialog is open
    expect(find.text('End session?'), findsOneWidget);
    await tester.tap(find.text('KEEP GOING'));
    await tester.pump(settle);
    expect(find.text('Shallow Wall Sit'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('END SESSION'));
    await tester.pumpAndSettle();
    expect(find.text('START STRENGTH ANYWAY'), findsOneWidget); // not logged
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
      expect(find.text('ANSWER ALL 5'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Recovering knee Both'));
      await tester.pump();

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
        await tester.tap(
          find.text('Single-leg balance on each recovering leg'),
        );
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

      // The new stint starts today, so yesterday's flare no longer counts:
      // only this morning's broken day remains → repeat the dose.
      expect(find.text('REPEAT THIS DOSE'), findsOneWidget);
      await scrollTo(tester, find.text('Calm & Activate'));
      expect(find.text('Calm & Activate'), findsOneWidget);
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

  group('two knees', () {
    Future<void> bothKnees(AppDatabase db) =>
        saveKneeSetup(db, const KneeSetup.both(first: Knee.right));

    testWidgets('check-in asks about each knee', (tester) async {
      await pumpApp(tester, seed: bothKnees);

      await tester.tap(find.text('Morning check-in'));
      await tester.pumpAndSettle();
      expect(find.text('Right knee'), findsOneWidget); // right goes first

      Future<void> tap(String label) async {
        final f = find.bySemanticsLabel(label);
        await tester.scrollUntilVisible(
          f,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pump();
      }

      for (final (knee, pain) in [('Right', 3), ('Left', 1)]) {
        await tap('$knee knee pain $pain');
        await tap('$knee knee Swelling Same');
        await tap('$knee knee Stiffness Same');
      }
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();
      expect(find.text('Left pain 1  ·  Right pain 3'), findsOneWidget);
    });

    testWidgets('recovering-leg exercises run on both legs', (tester) async {
      await pumpApp(tester, seed: bothKnees);
      await startSession(tester);

      await tester.tap(find.text('SKIP')); // wall sit
      await tester.pump(settle);
      await tester.tap(find.text('START NOW')); // band knee extension
      await tester.pump(settle);
      expect(find.text('SET 1 OF 3  ·  RIGHT LEG'), findsOneWidget);
      await tester.tap(find.text('DONE'));
      await tester.pump(settle);
      expect(find.text('SWITCH LEGS'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('SET 1 OF 3  ·  LEFT LEG'), findsOneWidget);
    });

    testWidgets('settings change which knees are in rehab', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.textContaining('Not set'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Recovering knee Both'));
      await tester.pumpAndSettle();
      expect(find.text('START EACH EXERCISE WITH'), findsOneWidget);
      expect(find.textContaining('run on both'), findsOneWidget);
    });
  });

  testWidgets('History shows which days had strength and which mobility', (
    tester,
  ) async {
    Future<void> log(AppDatabase db, SessionKind kind, int day) =>
        db.saveSession(
          programId: 'knee_meniscus',
          phaseId: 'p1',
          result: SessionResult(
            kind: kind,
            startedAt: DateTime(2026, 11, day, 18),
            endedAt: DateTime(2026, 11, day, 18, 30),
            painBefore: 1,
            painAfter: 2,
            items: const [],
          ),
        );
    await pumpApp(
      tester,
      seed: (db) async {
        await log(db, SessionKind.strength, 13); // Friday
        await log(db, SessionKind.daily, 13);
        await log(db, SessionKind.daily, 12); // Thursday
      },
    );

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Fri 13 Nov, strength and mobility, strength day'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Thu 12 Nov, mobility'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Wed 11 Nov, nothing logged, strength day'),
      findsOneWidget,
    );
    await scrollTo(tester, find.text('Thu 12 Nov'));
    expect(find.text('Fri 13 Nov'), findsOneWidget);
  });
}
