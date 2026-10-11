import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';

/// What the panel shows: the archive's latest levels, by key.
class RecentState {
  /// A state with [byKey] as each key's levels, newest first.
  const new({this.byKey = const {}});

  /// Each key's levels, newest first, the keys in the order they first
  /// appeared.
  final Map<String, List<Level>> byKey;
}

/// The view model behind the panel, which keeps the archive's latest levels,
/// by key: the history the archive answers with, then each level it publishes
/// on top.
class RecentViewModel extends Notifier<RecentState> {
  /// Every key's levels together, newest first.
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

  /// Shows [levels], newest first, by key. The keys already shown keep their
  /// places.
  void _show(List<KeyedLevel> levels) {
    _levels = levels;
    final byKey = {for (final keyExpr in state.byKey.keys) keyExpr: <Level>[]};
    for (final (:keyExpr, :level) in levels) {
      (byKey[keyExpr] ??= []).add(level);
    }
    state = RecentState(byKey: byKey);
  }
}

/// The panel's view model.
final recentViewModelProvider = NotifierProvider<RecentViewModel, RecentState>(
  RecentViewModel.new,
);
