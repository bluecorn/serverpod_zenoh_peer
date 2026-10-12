import 'package:flutter/material.dart';

/// The colour every view of the bridge is built from.
const seedColor = Color(0xFF82A3FF);

/// The theme of [brightness], its colours made from [seedColor] and kept close
/// to it, the title bar in the seed's container colour.
ThemeData themeOf(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.content,
  );
  return ThemeData(
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
    ),
  );
}
