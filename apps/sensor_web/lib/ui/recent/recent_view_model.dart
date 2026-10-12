import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/config/providers.dart';
import 'package:sensor_web/domain/sensed.dart';

/// What the panel shows: the archive's latest levels, by key.
class RecentState {
  /// A state with [byKey] as each key's levels, newest first, each with its
  /// sensor.
  const new({this.byKey = const {}});

  /// Each key's levels, newest first, the keys in the sensor list's order.
  final Map<String, List<SensedLevel>> byKey;
}

/// The view model behind the panel, which keeps the archive's latest levels,
/// by key.
class RecentViewModel extends Notifier<RecentState> {
  @override
  RecentState build() {
    ref.listen(recentLevelsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        // The keys in the sensor list's order, a tie keeping its place; a key
        // no longer among the latest levels leaves.
        final byKey = {
          for (final keyExpr in state.byKey.keys) keyExpr: <SensedLevel>[],
        };
        for (final sensed in value) {
          (byKey[sensed.level.keyExpr] ??= []).add(sensed);
        }
        byKey.removeWhere((_, levels) => levels.isEmpty);
        state = RecentState(
          byKey: Map.fromEntries(
            inSensorOrder(byKey.entries, (entry) => entry.value.first.sensor),
          ),
        );
      }
    });
    return const RecentState();
  }
}

/// The panel's view model.
final recentViewModelProvider = NotifierProvider<RecentViewModel, RecentState>(
  RecentViewModel.new,
);
