import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_node/ui/core/levels_card.dart';
import 'package:sensor_node/ui/core/sensor_card.dart';
import 'package:sensor_node/ui/monitor/monitor_view_model.dart';

/// The monitor's window: a title bar with its name and the routes its data
/// takes, and a column for each sensor, side by side, its live card above its
/// levels card.
class MonitorScreen extends ConsumerWidget {
  /// The window; it watches [monitorViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitor = ref.watch(monitorViewModelProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sensor monitor'),
            Text(
              "readings from the node over zenoh · levels through the server's "
              'zenoh door',
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final column in monitor.columns)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (column.live case final live?)
                    SensorCard(
                      keyExpr: live.keyExpr,
                      latest: live.state.latest,
                      count: live.state.count,
                      receives: monitor.receives,
                    ),
                  LevelsCard(sensor: column.sensor, levels: column.levels),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
