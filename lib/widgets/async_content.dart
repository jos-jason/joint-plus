import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_parser.dart';
import '../theme/tokens.dart';
import 'stark_primitives.dart';

/// Renders [builder] once [value] has data. Loading is a blank screen (content
/// loads in milliseconds). Errors are listed in full, which is mainly for
/// catching mistakes while editing the content JSON.
class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => builder(value),
      AsyncError(:final error) => ContentErrorView(error: error),
      _ => const SizedBox.expand(),
    };
  }
}

class ContentErrorView extends StatelessWidget {
  const ContentErrorView({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final lines = error is ContentException
        ? (error as ContentException).errors
        : [error.toString()];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(JSpace.gutter),
        children: [
          const SectionLabel('Content error'),
          const SizedBox(height: JSpace.md),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: JSpace.sm),
              child: Text(
                l,
                style: JType.secondary.copyWith(color: JColors.white),
              ),
            ),
        ],
      ),
    );
  }
}
