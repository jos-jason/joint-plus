import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Inline text tabs: uppercase labels, the active one white with a green tick.
/// Same visual language as the bottom nav, for switching views within a screen.
class StarkTabs extends StatelessWidget {
  const StarkTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Semantics(
            button: true,
            selected: i == index,
            label: labels[i],
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.only(right: JSpace.lg),
                child: SizedBox(
                  height: JSize.tapTarget,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[i].toUpperCase(),
                        style: JType.label.copyWith(
                          color: i == index ? JColors.white : JColors.grey,
                        ),
                      ),
                      const SizedBox(height: JSpace.sm),
                      Container(
                        width: 16,
                        height: 2,
                        color: i == index ? JColors.green : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
