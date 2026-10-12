import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';

/// One sensor's column on the monitor: the sensor, its latest reading with the
/// key it arrived on, once one has arrived, and its levels, newest first.
class MonitorColumn {
  /// The column of [sensor], with [live] once a reading has arrived and its
  /// [levels].
  const new({required this.sensor, this.live, this.levels = const []});

  /// The sensor the column is of.
  final Sensor sensor;

  /// The sensor's latest reading and count, with its key, once one arrived.
  final ({String keyExpr, SensorState state})? live;

  /// The sensor's levels, newest first.
  final List<Level> levels;
}

/// What the monitor's window shows: a column for each sensor, and whether its
/// readings are received here.
class MonitorState {
  /// A state of [columns], of readings received here when [receives] is true.
  const new({this.columns = const [], this.receives = false});

  /// A column for each sensor, in the sensor list's order.
  final List<MonitorColumn> columns;

  /// Whether the readings are received here.
  final bool receives;
}

/// The view model behind the monitor's window.
class MonitorViewModel extends Notifier<MonitorState> {
  @override
  MonitorState build() => const MonitorState();
}

/// The monitor window's view model.
final monitorViewModelProvider =
    NotifierProvider<MonitorViewModel, MonitorState>(MonitorViewModel.new);
