import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 0–10 pain picker: a row of 11 square cells. The selected value fills green.
/// A row of discrete taps is quicker and more exact than a slider.
class PainScale extends StatelessWidget {
  const PainScale({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 10,
    this.semanticPrefix = '',
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final int max;

  /// Read before each cell by screen readers, e.g. "Left knee".
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i <= max; i++)
              Expanded(
                child: _Cell(
                  n: i,
                  selected: value == i,
                  onTap: onChanged,
                  prefix: semanticPrefix,
                ),
              ),
          ],
        ),
        const SizedBox(height: JSpace.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('NONE', style: JType.label),
            Text('WORST', style: JType.label),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.n,
    required this.selected,
    required this.onTap,
    required this.prefix,
  });

  final String prefix;

  final int n;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: prefix.isEmpty ? 'Pain $n' : '$prefix pain $n',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(n),
        child: Container(
          height: JSize.tapTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? JColors.green : Colors.transparent,
            border: Border(
              top: const BorderSide(color: JColors.line),
              bottom: const BorderSide(color: JColors.line),
              left: n == 0
                  ? const BorderSide(color: JColors.line)
                  : BorderSide.none,
              right: const BorderSide(color: JColors.line),
            ),
          ),
          child: Text(
            '$n',
            style: JType.number.copyWith(
              color: selected ? JColors.black : JColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
