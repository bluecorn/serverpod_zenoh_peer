import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';

/// The node's one screen: a block for each key, with the key, its latest
/// reading to three decimals, the time it was stamped, in UTC, when the
/// reading has one, and its count.
class NodeScreen extends ConsumerWidget {
  /// The screen; it watches [nodeViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = ref.watch(nodeViewModelProvider);
    return Scaffold(
      body: Center(
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.headlineSmall,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              for (final MapEntry(key: keyExpr, value: sensor)
                  in node.sensors.entries)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(keyExpr),
                    Text('x ${_fixed(sensor.latest.x)}'),
                    Text('y ${_fixed(sensor.latest.y)}'),
                    Text('z ${_fixed(sensor.latest.z)}'),
                    if (sensor.latest.time case final time?)
                      Text('${_clock(time)} UTC'),
                    Text('${sensor.latest.number} readings'),
                    Text('${sensor.count} received here'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fixed(double value) => value.toStringAsFixed(3);

  /// [time] as hours, minutes, seconds and milliseconds, in UTC.
  static String _clock(DateTime time) =>
      time.toUtc().toIso8601String().substring(11, 23);
}
