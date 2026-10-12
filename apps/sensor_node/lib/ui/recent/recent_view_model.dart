import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';

/// What the panel shows: the archive's latest levels, by key.
class RecentState {
  /// A state with [byKey] as each key's levels, newest first.
  const new({this.byKey = const {}});

  /// Each key's levels, newest first, the keys in the sensor list's order.
  final Map<String, List<Level>> byKey;
}

/// The view model behind the panel, which keeps the archive's latest levels,
/// by key: the history the archive answers with, then each level it publishes
/// on top, the newest [recentCount] in all.
class RecentViewModel extends Notifier<RecentState> {
  /// The newest [recentCount] levels of every key together, newest first.
  var _levels = <KeyedLevel>[];

  @override
  RecentState build() {
    ref
      ..listen(recentLevelsProvider, (_, next) {
        if (next case AsyncData(:final value)) _show(value);
      })
      ..listen(liveLevelsProvider, (_, next) {
        if (next case AsyncData(:final value)) _show([value, ..._levels]);
      });
    return const RecentState();
  }

  /// Shows the newest [recentCount] of [levels], newest first, by key, the
  /// keys in the sensor list's order; keys of the same rank keep the places
  /// they had, and a key no longer among them leaves.
  void _show(List<KeyedLevel> levels) {
    _levels = levels.take(recentCount).toList();
    final byKey = {for (final keyExpr in state.byKey.keys) keyExpr: <Level>[]};
    for (final (:keyExpr, :level) in _levels) {
      (byKey[keyExpr] ??= []).add(level);
    }
    byKey.removeWhere((_, levels) => levels.isEmpty);
    final entries = byKey.entries.indexed.toList()
      ..sort((a, b) {
        final bySensor = compareSensors(
          a.$2.value.first.sensor,
          b.$2.value.first.sensor,
        );
        return bySensor != 0 ? bySensor : a.$1.compareTo(b.$1);
      });
    state = RecentState(byKey: Map.fromEntries(entries.map((e) => e.$2)));
  }
}

/// The panel's view model.
final recentViewModelProvider = NotifierProvider<RecentViewModel, RecentState>(
  RecentViewModel.new,
);
