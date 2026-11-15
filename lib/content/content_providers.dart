import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_loader.dart';
import 'models.dart';

/// All bundled content, loaded and validated once.
final contentProvider = FutureProvider<ContentLibrary>(
  (ref) => ContentLoader(rootBundle).load(),
);

/// The program the user is following. Only one program exists for now.
/// Becomes a persisted choice once there is more than one.
final activeProgramProvider = FutureProvider<Program>((ref) async {
  final lib = await ref.watch(contentProvider.future);
  return lib.program('knee_meniscus');
});
