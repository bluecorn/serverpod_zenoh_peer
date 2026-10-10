import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

/// The page, as the phone's own screen: a block for each key, with the key,
/// its latest reading to three decimals, and its count.
class WatchScreen extends ConsumerWidget {
  /// The page; it watches [watchViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(watchViewModelProvider);
    return Scaffold(
      body: Center(
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.headlineSmall,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              for (final MapEntry(key: keyExpr, value: sensor)
                  in watch.sensors.entries)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(keyExpr),
                    Text('x ${_fixed(sensor.latest.x)}'),
                    Text('y ${_fixed(sensor.latest.y)}'),
                    Text('z ${_fixed(sensor.latest.z)}'),
                    Text('${sensor.count} readings'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fixed(double value) => value.toStringAsFixed(3);
}
