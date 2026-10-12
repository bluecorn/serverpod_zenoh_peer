import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_node/ui/core/sensor_card.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';

/// The Live tab: a card for each key, in the order the keys arrived.
class NodeScreen extends ConsumerWidget {
  /// The screen; it watches [nodeViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = ref.watch(nodeViewModelProvider);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final MapEntry(key: keyExpr, value: sensor)
            in node.sensors.entries)
          SensorCard(
            keyExpr: keyExpr,
            latest: sensor.latest,
            count: sensor.count,
            receives: node.receives,
          ),
      ],
    );
  }
}
