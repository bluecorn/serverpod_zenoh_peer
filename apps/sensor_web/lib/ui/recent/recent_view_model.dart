import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/config/providers.dart';

/// What the panel shows: the archive's latest levels, by key.
class RecentState {
  /// A state with [byKey] as each key's levels, newest first.
  const new({this.byKey = const {}});

  /// Each key's levels, newest first, the keys in the order they first
  /// appeared.
  final Map<String, List<SensorLevel>> byKey;
}

/// The view model behind the panel, which keeps the archive's latest levels,
/// by key.
class RecentViewModel extends Notifier<RecentState> {
  @override
  RecentState build() {
    ref.listen(recentLevelsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        // The keys already shown keep their places; a key no longer among the
        // latest levels leaves.
        final byKey = {
          for (final keyExpr in state.byKey.keys) keyExpr: <SensorLevel>[],
        };
        for (final level in value) {
          (byKey[level.keyExpr] ??= []).add(level);
        }
        byKey.removeWhere((_, levels) => levels.isEmpty);
        state = RecentState(byKey: byKey);
      }
    });
    return const RecentState();
  }
}

/// The panel's view model.
final recentViewModelProvider = NotifierProvider<RecentViewModel, RecentState>(
  RecentViewModel.new,
);
