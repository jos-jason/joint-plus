import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: JColors.green,
    onPrimary: JColors.black,
    secondary: JColors.white,
    onSecondary: JColors.black,
    surface: JColors.black,
    onSurface: JColors.white,
    outline: JColors.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: JColors.black,
    canvasColor: JColors.black,
    // Stark: no ink ripples, no highlight washes.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textTheme: const TextTheme(
      displayLarge: JType.display,
      headlineMedium: JType.title,
      titleMedium: JType.heading,
      bodyLarge: JType.body,
      bodyMedium: JType.body,
      bodySmall: JType.secondary,
      labelSmall: JType.label,
    ),
    dividerTheme: const DividerThemeData(
      color: JColors.line,
      thickness: JSize.hairline,
      space: JSize.hairline,
    ),
    iconTheme: const IconThemeData(color: JColors.white, size: 22),
  );
}
