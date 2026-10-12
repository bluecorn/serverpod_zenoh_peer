import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_web/ui/page/page_view_model.dart';

/// The page: a title bar with its name and the route its data takes.
class PageScreen extends ConsumerWidget {
  /// The page; it watches [pageViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pageViewModelProvider);
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
    );
  }
}
