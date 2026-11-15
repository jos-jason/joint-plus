import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../content/models.dart';

/// The exercise's line drawing (`assets/illustrations/<id>.svg`), 4:3.
/// Shows nothing if the file is missing, so new content never breaks a screen.
class ExerciseIllustration extends StatelessWidget {
  const ExerciseIllustration(this.exercise, {super.key});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: SvgPicture.asset(
        exercise.illustrationAsset,
        fit: BoxFit.contain,
        semanticsLabel: 'Drawing of ${exercise.name}',
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
    );
  }
}
