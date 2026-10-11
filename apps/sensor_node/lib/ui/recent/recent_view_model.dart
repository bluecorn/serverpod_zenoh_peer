import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';

/// What the panel shows: the archive's latest levels, by key.
class RecentState {
  /// A state with [byKey] as each key's levels, newest first.
  const new({this.byKey = const {}});

  /// Each key's levels, newest first, the keys in the order they first
  /// appeared.
  final Map<String, List<Level>> byKey;
}

/// The view model behind the panel, which keeps the archive's latest levels,
/// by key.
class RecentViewModel extends Notifier<RecentState> {
  @override
  RecentState build() => const RecentState();
}

/// The panel's view model.
final recentViewModelProvider = NotifierProvider<RecentViewModel, RecentState>(
  RecentViewModel.new,
);
