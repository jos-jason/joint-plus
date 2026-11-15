import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../content/models.dart';
import '../../widgets/stark_primitives.dart';

/// A dose with its rest resolved against the session default. Passed to the
/// exercise detail route as `extra`.
typedef SessionDose = ({Dose dose, int restSec});

/// One exercise in a session list: name, dose underneath, opens the detail.
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.exercise,
    required this.dose,
    required this.restSec,
  });

  final Exercise exercise;
  final Dose dose;
  final int restSec;

  @override
  Widget build(BuildContext context) {
    final amount = dose.describe(exercise);
    return StarkRow(
      title: exercise.name,
      subtitle: dose.optional ? 'Optional  ·  $amount' : amount,
      onTap: () => context.push(
        Routes.exercise(exercise.id),
        extra: (dose: dose, restSec: restSec),
      ),
    );
  }
}

/// All rows for a session, required first then optional extras.
class SessionExerciseList extends StatelessWidget {
  const SessionExerciseList({
    super.key,
    required this.session,
    required this.exercises,
  });

  final SessionTemplate session;
  final Map<String, Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final d in [...session.required, ...session.optional])
          ExerciseRow(
            exercise: exercises[d.exerciseId]!,
            dose: d,
            restSec: d.restSec ?? session.restSec,
          ),
      ],
    );
  }
}
