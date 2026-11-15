import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Square on/off switch: hairline box, knob slides right and fills green.
class StarkSwitch extends StatelessWidget {
  const StarkSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: JSize.tapTarget + 8,
          height: JSize.tapTarget,
          child: Center(
            child: Container(
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(color: value ? JColors.green : JColors.grey),
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                color: value ? JColors.green : JColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
