import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 1px full-bleed hairline.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.color = JColors.line});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: JSize.hairline, color: color);
}

/// Small uppercase section label, e.g. "PHASE 1".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = JColors.grey});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: JType.label.copyWith(color: color));
}

/// A tappable list row: label on the left, optional value/trailing on the right,
/// hairline underneath.
class StarkRow extends StatelessWidget {
  const StarkRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: JSpace.gutter,
              vertical: JSpace.md + 2,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: JSpace.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: JType.body),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: JType.secondary),
                      ],
                    ],
                  ),
                ),
                ?trailing,
                if (onTap != null && trailing == null)
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: JColors.grey,
                  ),
              ],
            ),
          ),
          const Hairline(),
        ],
      ),
    );
  }
}

/// Square icon button with a 48px hit area.
class StarkIconButton extends StatelessWidget {
  const StarkIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: JSize.tapTarget,
          child: Icon(icon, color: JColors.white),
        ),
      ),
    );
  }
}
