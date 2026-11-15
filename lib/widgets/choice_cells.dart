import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A row of equal, square-cornered options; the chosen one fills green.
/// Same look as the pain scale, for short word choices.
class ChoiceCells extends StatelessWidget {
  const ChoiceCells({
    super.key,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.semanticPrefix = '',
  });

  final List<String> labels;
  final int? value;
  final ValueChanged<int> onChanged;

  /// Read before each label by screen readers, e.g. "Swelling".
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, label) in labels.indexed)
          Expanded(
            child: Semantics(
              button: true,
              selected: value == i,
              label: '$semanticPrefix $label'.trim(),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  height: JSize.tapTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == i ? JColors.green : Colors.transparent,
                    border: Border(
                      top: const BorderSide(color: JColors.line),
                      bottom: const BorderSide(color: JColors.line),
                      left: i == 0
                          ? const BorderSide(color: JColors.line)
                          : BorderSide.none,
                      right: const BorderSide(color: JColors.line),
                    ),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: JType.label.copyWith(
                      color: value == i ? JColors.black : JColors.white,
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
