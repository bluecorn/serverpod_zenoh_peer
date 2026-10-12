import 'package:flutter/material.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/core/theme.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = onCardColorOf(theme.colorScheme);
    final text = theme.textTheme.apply(bodyColor: onCard, displayColor: onCard);
    final secondary = text.bodyMedium?.copyWith(
      color: onCard.withValues(alpha: 0.72),
    );
    final value = text.bodyLarge?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sensor.label, style: text.titleLarge),
            Text(sensor.unit, style: secondary),
            const SizedBox(height: 8),
            for (final level in levels)
              Row(
                children: [
                  Text(_clock(level.time), style: value),
                  const Spacer(),
                  Text(level.value.toStringAsFixed(3), style: value),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// [time] as hours, minutes and seconds, in UTC.
  static String _clock(DateTime time) =>
      time.toUtc().toIso8601String().substring(11, 19);
}
