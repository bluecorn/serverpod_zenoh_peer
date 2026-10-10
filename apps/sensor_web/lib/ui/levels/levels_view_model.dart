import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/config/providers.dart';

/// What the page shows: the latest level on each key.
class LevelsState {
  /// A state with [latest] as the newest level on each key.
  const new({this.latest = const {}});

  /// The newest level on each key a level has arrived on, in the order the
  /// keys first arrived.
  final Map<String, SensorLevel> latest;
}

/// The view model behind the page, which keeps the latest level on each key.
class LevelsViewModel extends Notifier<LevelsState> {
  @override
  LevelsState build() {
    ref.listen(levelsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        state = LevelsState(latest: {...state.latest, value.keyExpr: value});
      }
    });
    return const LevelsState();
  }
}

/// The view model of the page.
final levelsViewModelProvider = NotifierProvider<LevelsViewModel, LevelsState>(
  LevelsViewModel.new,
);
