import 'package:flutter/material.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';

/// A sensor's card on the page, as the phone's: its label, its key, its latest
/// reading on each axis with the unit, and at its foot the stamp, the phone's
/// number and how many readings reached the page.
class SensorCard extends StatelessWidget {
  /// The card of [latest], the newest reading of [sensor], after [count]
  /// reached the page.
  const new({
    required this.latest,
    required this.sensor,
    required this.count,
    super.key,
  });

  /// The newest reading.
  final SensorReading latest;

  /// The sensor it is of.
  final Sensor sensor;

  /// How many readings reached the page.
  final int count;

  @override
  Widget build(BuildContext context) => const Card();
}
