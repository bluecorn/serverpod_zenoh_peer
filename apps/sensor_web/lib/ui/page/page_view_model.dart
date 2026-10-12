import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/ui/recent/recent_view_model.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

/// One sensor's column on the page: the sensor, its latest reading and count,
/// once one has arrived, and its levels, newest first.
class PageColumn {
  /// The column of [sensor], with [live] once a reading has arrived and its
  /// [levels].
  const new({required this.sensor, this.live, this.levels = const []});

  /// The sensor the column is of.
  final Sensor sensor;

  /// The sensor's latest reading and count, once one has arrived.
  final SensorState? live;

  /// The sensor's levels, newest first.
  final List<SensorLevel> levels;
}

/// What the page shows: a column for each sensor.
class PageState {
  /// A state of [columns].
  const new({this.columns = const []});

  /// A column for each sensor, in the sensor list's order.
  final List<PageColumn> columns;
}

/// The view model behind the page, which pairs the readings' view model with
/// the levels' by their sensor: a sensor's latest reading and its levels in
/// one column, the columns in the sensor list's order.
class PageViewModel extends Notifier<PageState> {
  @override
  PageState build() {
    final watch = ref.watch(watchViewModelProvider);
    final recent = ref.watch(recentViewModelProvider);
    final columns = <Sensor, PageColumn>{
      for (final live in watch.sensors.values)
        live.sensor: PageColumn(sensor: live.sensor, live: live),
    };
    for (final levels in recent.byKey.values) {
      final sensor = levels.first.sensor;
      columns[sensor] = PageColumn(
        sensor: sensor,
        live: columns[sensor]?.live,
        levels: [for (final (:level, sensor: _) in levels) level],
      );
    }
    return PageState(
      columns: inSensorOrder(columns.values, (column) => column.sensor),
    );
  }
}

/// The page's view model.
final pageViewModelProvider = NotifierProvider<PageViewModel, PageState>(
  PageViewModel.new,
);
