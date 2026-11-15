import 'package:go_router/go_router.dart';

import '../features/checkin/checkin_screen.dart';
import '../features/exercise/exercise_detail_screen.dart';
import '../features/exercise/exercise_row.dart';
import '../content/models.dart';
import '../features/history/history_screen.dart';
import '../features/player/player_screen.dart';
import '../features/program/phase_detail_screen.dart';
import '../features/program/program_screen.dart';
import '../features/settings/components_screen.dart';
import '../features/start/entry_check_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/today_screen.dart';
import 'shell.dart';

abstract final class Routes {
  static const today = '/today';
  static const program = '/program';
  static const history = '/history';
  static const settings = '/settings';
  static const components = '/settings/components';
  static const checkIn = '/checkin';
  static const start = '/start';

  static String phase(String id) => '/phase/$id';

  /// Pass a [SessionDose] as `extra` to show sets/reps/rest.
  static String exercise(String id) => '/exercise/$id';

  /// The guided player for the current phase's session of this kind.
  static String session(SessionKind kind) => '/session/${kind.name}';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.today,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.today,
              builder: (context, state) => const TodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.program,
              builder: (context, state) => const ProgramScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.history,
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full-screen routes, pushed over the tab bar.
    GoRoute(
      path: '/phase/:id',
      builder: (context, state) =>
          PhaseDetailScreen(phaseId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/exercise/:id',
      builder: (context, state) => ExerciseDetailScreen(
        exerciseId: state.pathParameters['id']!,
        dose: state.extra is SessionDose ? state.extra as SessionDose : null,
      ),
    ),
    GoRoute(
      path: '/session/:kind',
      builder: (context, state) => PlayerScreen(
        kind: SessionKind.values.byName(state.pathParameters['kind']!),
      ),
    ),
    GoRoute(
      path: Routes.start,
      builder: (context, state) => const EntryCheckScreen(),
    ),
    GoRoute(
      path: Routes.checkIn,
      builder: (context, state) => const CheckInScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'components',
          builder: (context, state) => const ComponentsScreen(),
        ),
      ],
    ),
  ],
);
