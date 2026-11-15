import 'package:flutter/painting.dart';

/// Design tokens. The palette is deliberately tiny:
/// black canvas, white content, and green used ONLY for "act on this / active / done".
abstract final class JColors {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const green = Color(0xFF00E676);
  static const grey = Color(0xFF6B6B6B);

  /// Hairline dividers and inactive tracks.
  static const line = Color(0x33FFFFFF);
}

abstract final class JSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Horizontal page gutter.
  static const gutter = 24.0;
}

abstract final class JSize {
  static const hairline = 1.0;
  static const buttonHeight = 64.0;
  static const tapTarget = 48.0;
}

abstract final class JType {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Huge numerals: timers, rep counters.
  static const display = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
    color: JColors.white,
    fontFeatures: _tabular,
  );

  /// Screen headline: session or exercise name.
  static const title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.1,
    color: JColors.white,
  );

  static const heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
    color: JColors.white,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: JColors.white,
  );

  static const secondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: JColors.grey,
  );

  /// Small uppercase labels: section headers, buttons, nav.
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
    height: 1.2,
    color: JColors.grey,
  );

  static const number = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: JColors.white,
    fontFeatures: _tabular,
  );
}
