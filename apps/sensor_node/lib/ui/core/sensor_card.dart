import 'package:flutter/material.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/core/theme.dart';

/// A sensor's card: its label, its key, its latest reading on each axis with
/// the unit, and at its foot the stamp when there is one, the node's number,
/// and, where the readings are received, how many arrived.
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
    final sensor = latest.sensor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sensor.label, style: text.titleLarge),
            Text(keyExpr, style: secondary),
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
                if (latest.time case final time?)
                  Text('${_clock(time)} UTC', style: secondary),
                const Spacer(),
                Text('${latest.number} readings', style: secondary),
              ],
            ),
            if (receives)
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
