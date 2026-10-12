import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

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

/// The view model behind the monitor's window, which pairs the readings'
/// view model with the levels' by their sensor: a sensor's latest reading and
/// its levels in one column, the columns in the sensor list's order.
class MonitorViewModel extends Notifier<MonitorState> {
  @override
  MonitorState build() {
    final node = ref.watch(nodeViewModelProvider);
    final recent = ref.watch(recentViewModelProvider);
    final columns = <Sensor, MonitorColumn>{};
    for (final MapEntry(key: keyExpr, value: state) in node.sensors.entries) {
      final sensor = state.latest.sensor;
      columns[sensor] = MonitorColumn(
        sensor: sensor,
        live: (keyExpr: keyExpr, state: state),
      );
    }
    for (final levels in recent.byKey.values) {
      final sensor = levels.first.sensor;
      columns[sensor] = MonitorColumn(
        sensor: sensor,
        live: columns[sensor]?.live,
        levels: levels,
      );
    }
    final ordered = columns.values.indexed.toList()
      ..sort((a, b) {
        final bySensor = compareSensors(a.$2.sensor, b.$2.sensor);
        return bySensor != 0 ? bySensor : a.$1.compareTo(b.$1);
      });
    return MonitorState(
      columns: [for (final (_, column) in ordered) column],
      receives: node.receives,
    );
  }
}

/// The monitor window's view model.
final monitorViewModelProvider =
    NotifierProvider<MonitorViewModel, MonitorState>(MonitorViewModel.new);
