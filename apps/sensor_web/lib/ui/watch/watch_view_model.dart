import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';

/// What the page shows for one key: the latest reading on it, and how many
/// there were.
class SensorState {
  /// A state with [latest] as the newest reading and [count] readings so far.
  const new({required this.latest, required this.count});

  /// The newest reading on the key.
  final SensorReading latest;

  /// How many readings have arrived on the key.
  final int count;
}

/// What the page shows: the state of each key.
class WatchState {
  /// A state with [sensors] as the state of each key.
  const new({this.sensors = const {}});

  /// The state of each key a reading has arrived on, in the order the keys
  /// first arrived.
  final Map<String, SensorState> sensors;
}

/// The view model behind the page, which keeps the latest reading and counts
/// the readings, for each key.
class WatchViewModel extends Notifier<WatchState> {
  @override
  WatchState build() => const WatchState();
}

/// The page's view model.
final watchViewModelProvider = NotifierProvider<WatchViewModel, WatchState>(
  WatchViewModel.new,
);
