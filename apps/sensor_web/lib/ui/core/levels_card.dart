import 'package:flutter/material.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';

/// A sensor's levels card on the page, as the phone's: its label, what its
/// levels are in its unit, and its levels, newest first.
class LevelsCard extends StatelessWidget {
  /// The card of [sensor]'s [levels], newest first.
  const new({required this.sensor, required this.levels, super.key});

  /// The sensor the levels are of.
  final Sensor sensor;

  /// Its levels, newest first.
  final List<SensorLevel> levels;

  @override
  Widget build(BuildContext context) => const Card();
}
