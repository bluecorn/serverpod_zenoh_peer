import 'package:flutter/material.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/ui/core/theme.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = onCardColorOf(theme.colorScheme);
    final text = theme.textTheme.apply(bodyColor: onCard, displayColor: onCard);
    final secondary = text.bodyMedium?.copyWith(
      color: onCard.withValues(alpha: 0.72),
    );
    final value = text.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sensor.label, style: text.titleLarge),
            Text(latest.keyExpr, style: secondary),
            const SizedBox(height: 12),
            for (final (axis, reading) in [
              ('x', latest.x),
              ('y', latest.y),
              ('z', latest.z),
            ])
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(axis, style: text.titleMedium),
                  ),
                  SizedBox(
                    width: 96,
                    child: Text(
                      reading.toStringAsFixed(3),
                      textAlign: TextAlign.right,
                      style: value,
                    ),
                  ),
                  if (sensor.unit.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(sensor.unit, style: text.titleMedium),
                  ],
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${_clock(latest.time)} UTC', style: secondary),
                const Spacer(),
                Text('${latest.number} readings', style: secondary),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('$count received here', style: secondary),
            ),
          ],
        ),
      ),
    );
  }

  /// [time] as hours, minutes, seconds and milliseconds, in UTC.
  static String _clock(DateTime time) =>
      time.toUtc().toIso8601String().substring(11, 23);
}
