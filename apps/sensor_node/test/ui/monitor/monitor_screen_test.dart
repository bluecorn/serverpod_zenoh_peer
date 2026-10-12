import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/core/levels_card.dart';
import 'package:sensor_node/ui/core/sensor_card.dart';
import 'package:sensor_node/ui/monitor/monitor_screen.dart';
import 'package:sensor_node/ui/monitor/monitor_view_model.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';

import '../../support/fakes.dart';

/// Pumps the monitor's window at the size the Linux runner opens it, over a
/// view model that holds [state].
Future<void> _pumpMonitor(WidgetTester tester, MonitorState state) async {
  tester.view
    ..physicalSize = const Size(1280, 720)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer.test(
    overrides: [
      monitorViewModelProvider.overrideWith(() => FakeMonitorViewModel(state)),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: MonitorScreen()),
    ),
  );
}

void main() {
  testWidgets('the monitor shows a column per sensor, its live card above its '
      'levels card', (tester) async {
    // A fake: a view model that holds the accelerometer's column, a reading
    // and two levels, and the gyroscope's, a reading and no levels yet.
    Reading reading(Sensor sensor) =>
        Reading(sensor: sensor, number: 42, x: 0, y: 0, z: 1);
    Level level(int second) => Level(
      sensor: accelerometer,
      time: DateTime.utc(2026, 10, 12, 12, 0, second),
      value: 0.5,
    );
    final accel = MonitorColumn(
      sensor: accelerometer,
      live: (
        keyExpr: 'sensor/phone/accel',
        state: SensorState(latest: reading(accelerometer), count: 40),
      ),
      levels: [level(2), level(1)],
    );
    final gyro = MonitorColumn(
      sensor: gyroscope,
      live: (
        keyExpr: 'sensor/phone/gyro',
        state: SensorState(latest: reading(gyroscope), count: 41),
      ),
    );

    // The code to implement: the window, built once from that state.
    await _pumpMonitor(
      tester,
      MonitorState(columns: [accel, gyro], receives: true),
    );

    // The claim: two columns side by side, the accelerometer's on the left,
    // each its live card above its levels card.
    final live = find.byType(SensorCard);
    final levels = find.byType(LevelsCard);
    expect(live, findsNWidgets(2));
    expect(levels, findsNWidgets(2));
    final columns = [
      for (var i = 0; i < 2; i += 1)
        (
          sensor: tester.widget<SensorCard>(live.at(i)).latest.sensor,
          left: tester.getTopLeft(live.at(i)).dx,
          levelsLeft: tester.getTopLeft(levels.at(i)).dx,
          above:
              tester.getTopLeft(live.at(i)).dy <
              tester.getTopLeft(levels.at(i)).dy,
        ),
    ];
    expect(columns.map((c) => c.sensor), [accelerometer, gyroscope]);
    expect(columns[0].left, lessThan(columns[1].left));
    expect(columns.map((c) => c.left == c.levelsLeft), [true, true]);
    expect(columns.map((c) => c.above), [true, true]);
  });
}
