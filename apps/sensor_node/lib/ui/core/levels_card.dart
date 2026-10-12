import 'package:flutter/material.dart';
import 'package:sensor_core/sensor_core.dart';

/// A sensor's levels card: its label, its unit, and its levels, newest first,
/// each the second it covers, in UTC, and its value.
class LevelsCard extends StatelessWidget {
  /// The card of [sensor]'s [levels], newest first.
  const new({required this.sensor, required this.levels, super.key});

  /// The sensor the levels are of.
  final Sensor sensor;

  /// Its levels, newest first.
  final List<Level> levels;

  @override
  Widget build(BuildContext context) => const Card();
}
