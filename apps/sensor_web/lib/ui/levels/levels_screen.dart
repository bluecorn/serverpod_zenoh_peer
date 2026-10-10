import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_web/ui/levels/levels_view_model.dart';

/// The page: a block for each key, with the key, its latest vibration level
/// to three decimals, and the second it was measured over, in UTC.
class LevelsScreen extends ConsumerWidget {
  /// The page; it watches [levelsViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(levelsViewModelProvider);
    return Scaffold(
      body: Center(
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.headlineSmall,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              for (final MapEntry(key: keyExpr, value: level)
                  in levels.latest.entries)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(keyExpr),
                    Text(level.level.toStringAsFixed(3)),
                    Text('${_clock(level.time)} UTC'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _clock(DateTime time) => [
    time.hour,
    time.minute,
    time.second,
  ].map((part) => '$part'.padLeft(2, '0')).join(':');
}
