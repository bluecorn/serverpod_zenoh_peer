import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_web/ui/core/levels_card.dart';
import 'package:sensor_web/ui/core/sensor_card.dart';
import 'package:sensor_web/ui/page/page_view_model.dart';

/// The page: a title bar with its name and the route its data takes, and a
/// column for each sensor, its live card above its levels card, side by side
/// in a wide browser and one under the other in a narrow one.
class PageScreen extends ConsumerWidget {
  /// The page; it watches [pageViewModelProvider].
  const new({super.key});

  /// Below this width, in logical pixels, the page is one column.
  static const narrow = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pageViewModelProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sensor page'),
            Text(
              "readings and levels through Serverpod's web door",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appBarTheme.foregroundColor,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          List<Widget> cardsOf(PageColumn column) => [
            if (column.live case final live?)
              SensorCard(
                latest: live.latest,
                sensor: column.sensor,
                count: live.count,
              )
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('no readings yet'),
              ),
            LevelsCard(sensor: column.sensor, levels: column.levels),
          ];
          if (constraints.maxWidth < narrow) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [for (final column in page.columns) ...cardsOf(column)],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final column in page.columns)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: cardsOf(column),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
