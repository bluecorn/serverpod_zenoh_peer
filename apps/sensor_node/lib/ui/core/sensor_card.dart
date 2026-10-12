import 'package:flutter/material.dart';
import 'package:sensor_core/sensor_core.dart';

/// A sensor's card: its label, its key, its latest reading on each axis with
/// the unit, and at its foot the stamp and the node's number.
class SensorCard extends StatelessWidget {
  /// The card of [latest], the newest reading on [keyExpr], after [count]
  /// readings, received here when [receives] is true.
  const new({
    required this.keyExpr,
    required this.latest,
    required this.count,
    required this.receives,
    super.key,
  });

  /// The key the readings travel on.
  final String keyExpr;

  /// The newest reading on the key.
  final Reading latest;

  /// How many readings arrived here, or were published.
  final int count;

  /// Whether the readings are received here.
  final bool receives;

  @override
  Widget build(BuildContext context) => const Card();
}
