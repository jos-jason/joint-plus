import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum StarkButtonKind {
  /// Green fill. One per screen: the thing to do next.
  primary,

  /// White outline.
  secondary,
}

/// Full-width, square-cornered button with an uppercase label.
class StarkButton extends StatelessWidget {
  const StarkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = StarkButtonKind.primary,
  });

  const StarkButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : kind = StarkButtonKind.secondary;

  final String label;
  final VoidCallback? onPressed;
  final StarkButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final primary = kind == StarkButtonKind.primary;

    final fg = !enabled
        ? JColors.grey
        : primary
        ? JColors.black
        : JColors.white;
    final bg = primary && enabled ? JColors.green : Colors.transparent;
    final border = primary && enabled
        ? null
        : Border.all(
            color: enabled ? JColors.white : JColors.line,
            width: JSize.hairline,
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: JSize.buttonHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, border: border),
          child: Text(
            label.toUpperCase(),
            style: JType.label.copyWith(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ),
    );
  }
}
