import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_node/ui/core/levels_card.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

/// The archive's latest levels: the phone's History tab, and the monitor's
/// panel. A heading, then a levels card for each key, in the order the keys
/// first appeared; while there are none, a line that says so.
class RecentPanel extends ConsumerWidget {
  /// The panel; it watches [recentViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentViewModelProvider);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            'Vibration level, per second (UTC)',
            style: text.titleMedium,
          ),
        ),
        if (recent.byKey.isEmpty)
          const Padding(
            padding: EdgeInsets.all(4),
            child: Text('no levels yet'),
          ),
        for (final levels in recent.byKey.values)
          LevelsCard(sensor: levels.first.sensor, levels: levels),
      ],
    );
  }
}
