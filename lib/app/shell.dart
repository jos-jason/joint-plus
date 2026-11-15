import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/stark_primitives.dart';

/// Root scaffold with the three-tab bottom bar: Today · Program · History.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = ['Today', 'Program', 'History'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _StarkNavBar(
        labels: _tabs,
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          // Tapping the active tab pops it back to its root.
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _StarkNavBar extends StatelessWidget {
  const _StarkNavBar({
    required this.labels,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: JColors.black,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Hairline(),
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: _NavItem(
                        label: labels[i],
                        active: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: JType.label.copyWith(
                color: active ? JColors.white : JColors.grey,
              ),
            ),
            const SizedBox(height: JSpace.sm),
            // Green tick marks the active tab.
            Container(
              width: 16,
              height: 2,
              color: active ? JColors.green : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
