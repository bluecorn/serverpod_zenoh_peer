import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/monitor/monitor_view_model.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

import '../../support/fakes.dart';

void main() {
  test("the monitor's view model pairs each sensor's latest reading with its "
      "levels, in the sensor list's order", () {
    // Fakes: the readings' view model, holding the gyroscope's reading, and
    // the levels', holding the gyroscope's levels and the accelerometer's.
    const gyroLive = SensorState(
      latest: Reading(sensor: gyroscope, number: 9, x: 0, y: 0, z: 1),
      count: 7,
    );
    List<Level> levels(Sensor sensor) => [
      Level(sensor: sensor, time: DateTime.utc(2026, 10, 12, 12), value: 0.5),
    ];
    final gyroLevels = levels(gyroscope);
    final accelLevels = levels(accelerometer);
    final container = ProviderContainer.test(
      overrides: [
        nodeViewModelProvider.overrideWith(
          () => FakeNodeViewModel(
            const NodeState(
              sensors: {'sensor/phone/gyro': gyroLive},
              receives: true,
            ),
          ),
        ),
        recentViewModelProvider.overrideWith(
          () => FakeRecentViewModel(
            RecentState(
              byKey: {
                'archive/phone/gyro': gyroLevels,
                'archive/phone/accel': accelLevels,
              },
            ),
          ),
        ),
      ],
    );

    // The code to implement: the monitor's state, from the two.
    final state = container.read(monitorViewModelProvider);

    // The claim: the accelerometer's column first, its levels and no reading
    // yet, then the gyroscope's, its reading with its key and its levels;
    // the readings received here.
    final columns = state.columns
        .map((c) => (c.sensor, c.live?.keyExpr, c.live?.state, c.levels))
        .toList();
    expect(columns, [
      (accelerometer, null, null, accelLevels),
      (gyroscope, 'sensor/phone/gyro', gyroLive, gyroLevels),
    ]);
    expect(state.receives, isTrue);
  });
}
