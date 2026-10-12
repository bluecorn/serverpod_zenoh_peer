import 'package:flutter/material.dart';

/// The colour every view of the bridge is built from.
const seedColor = Color(0xFF82A3FF);

/// The theme of [brightness], its colours made from [seedColor].
ThemeData themeOf(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  ),
);
