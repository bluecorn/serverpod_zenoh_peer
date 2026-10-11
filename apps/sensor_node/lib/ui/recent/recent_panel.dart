import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

/// The panel beside the phone's screen in the monitor role: the archive's
/// latest levels, each key with its levels newest first, each the second it
/// covers, in UTC, and the level to three decimals.
class RecentPanel extends ConsumerWidget {
  /// The panel; it watches [recentViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentViewModelProvider);
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            'vibration level, last $recentCount (UTC)',
            style: theme.titleLarge,
          ),
          for (final MapEntry(key: keyExpr, value: levels)
              in recent.byKey.entries) ...[
            Text(keyExpr, style: theme.titleMedium),
            for (final level in levels)
              Text(
                '${_clock(level.time)}   ${level.value.toStringAsFixed(3)}',
                style: theme.bodyLarge,
              ),
          ],
        ],
      ),
    );
  }

  /// [time] as hours, minutes and seconds, in UTC.
  static String _clock(DateTime time) =>
      time.toUtc().toIso8601String().substring(11, 19);
}
