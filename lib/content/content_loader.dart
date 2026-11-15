import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'content_parser.dart';
import 'models.dart';

/// Loads content from the asset bundle. `index.json` lists the exercise library
/// and every program file, so adding a program is a data-only change:
/// drop a JSON file in `assets/content/programs/` and list it in the index.
class ContentLoader {
  const ContentLoader(this.bundle);

  static const indexPath = 'assets/content/index.json';

  final AssetBundle bundle;

  Future<ContentLibrary> load() async {
    final index = await _json(indexPath);
    if (index is! Map<String, Object?>) {
      throw ContentException(['$indexPath: expected an object']);
    }
    final exercisesPath = index['exercises'];
    final programPaths = index['programs'];
    if (exercisesPath is! String || programPaths is! List) {
      throw ContentException([
        '$indexPath: needs "exercises" (string) and "programs" (list)',
      ]);
    }

    final results = await Future.wait([
      _json(exercisesPath),
      for (final p in programPaths) _json(p as String),
    ]);

    return ContentParser.parse(
      exercisesJson: results.first,
      programsJson: results.sublist(1),
    );
  }

  Future<Object?> _json(String path) async {
    try {
      return jsonDecode(await bundle.loadString(path));
    } on FormatException catch (e) {
      throw ContentException(['$path: invalid JSON: ${e.message}']);
    } on FlutterError {
      throw ContentException([
        '$path: asset not found (is it in pubspec.yaml?)',
      ]);
    }
  }
}
