import 'package:flutter/material.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/ui/core/theme.dart';

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
            Text(_described(sensor.unit), style: secondary),
            const SizedBox(height: 8),
            for (final level in levels)
              Row(
                children: [
                  Text(_clock(level.time), style: value),
                  const Spacer(),
                  Text(level.level.toStringAsFixed(3), style: value),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// What a level is, in [unit] when the sensor has one: the vibration in one
  /// second, the root mean square of the readings' magnitudes around their
  /// mean, as the server computes it.
  static String _described(String unit) => unit.isEmpty
      ? 'vibration: spread of the magnitude around its mean'
      : 'vibration: spread of the magnitude around its mean, in $unit';

  /// [time] as hours, minutes and seconds, in UTC.
  static String _clock(DateTime time) =>
      time.toUtc().toIso8601String().substring(11, 19);
}
