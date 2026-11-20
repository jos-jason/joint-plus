import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'stark_primitives.dart';

/// Top-of-screen header: small label, big title, optional trailing action.
/// Pass [onBack] to show a back arrow in place of the label row's left edge.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.label,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? label;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        JSpace.gutter,
        JSpace.md,
        JSpace.sm,
        JSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: JSize.tapTarget,
            child: Row(
              children: [
                if (onBack != null)
                  Transform.translate(
                    offset: const Offset(-12, 0),
                    child: StarkIconButton(
                      icon: Icons.arrow_back,
                      onPressed: onBack!,
                      semanticLabel: 'Back',
                    ),
                  )
                else if (label != null)
                  Flexible(child: SectionLabel(label!)),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: JSpace.sm),
          Text(title, style: JType.title),
        ],
      ),
    );
  }
}
