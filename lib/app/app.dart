import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../reminders/reminder_providers.dart';
import '../theme/app_theme.dart';
import 'router.dart';

class JointPlusApp extends ConsumerStatefulWidget {
  const JointPlusApp({super.key});

  @override
  ConsumerState<JointPlusApp> createState() => _JointPlusAppState();
}

class _JointPlusAppState extends ConsumerState<JointPlusApp> {
  late final GoRouter _router = buildRouter();

  @override
  void initState() {
    super.initState();
    // A tapped reminder opens its screen on top of Today.
    ref
        .read(reminderControllerProvider)
        .start(
          onOpen: (route) {
            if (route != Routes.today) _router.push(route);
          },
        )
        .catchError((Object e) => debugPrint('Reminders unavailable: $e'));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: MaterialApp.router(
        title: 'Joint+',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
