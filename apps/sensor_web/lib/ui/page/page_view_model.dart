import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
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

/// The view model behind the page.
class PageViewModel extends Notifier<PageState> {
  @override
  PageState build() => const PageState();
}

/// The page's view model.
final pageViewModelProvider = NotifierProvider<PageViewModel, PageState>(
  PageViewModel.new,
);
