import 'package:flutter/material.dart';

/// The colour every view of the bridge is built from.
const seedColor = Color(0xFF82A3FF);

/// The colour of a card: the seed's tonal partner, light in a light theme
/// and dark in a dark one.
Color cardColorOf(ColorScheme scheme) => scheme.secondaryContainer;

/// The colour of what a card holds, legible on [cardColorOf].
Color onCardColorOf(ColorScheme scheme) => scheme.onSecondaryContainer;

/// The theme of [brightness], its colours made from [seedColor] and kept close
/// to it, the title bar in the seed's container colour and the cards in its
/// tonal partner's.
ThemeData themeOf(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.content,
  );
  return ThemeData(
    colorScheme: scheme,
    cardTheme: CardThemeData(color: cardColorOf(scheme)),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
    ),
  );
}
