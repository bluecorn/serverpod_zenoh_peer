import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

/// The panel beside the phone's screen in the monitor role: the archive's
/// latest levels.
class RecentPanel extends ConsumerWidget {
  /// The panel; it watches [recentViewModelProvider].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox();
}
