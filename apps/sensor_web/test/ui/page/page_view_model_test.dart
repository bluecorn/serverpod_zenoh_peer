import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/ui/page/page_view_model.dart';
import 'package:sensor_web/ui/recent/recent_view_model.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

import '../../support/fakes.dart';

void main() {
  test("the page's view model pairs each sensor's latest reading with its "
      "levels, in the sensor list's order", () {
    // Fakes: the readings' view model, holding the gyroscope's reading, and
    // the levels', holding the gyroscope's levels and the accelerometer's.
    final gyroLive = SensorState(
      latest: SensorReading(
        keyExpr: 'sensor/phone/gyro',
        number: 9,
        x: 0,
        y: 0,
        z: 1,
        time: DateTime.utc(2026, 10, 12, 12),
      ),
      sensor: gyroscope,
      count: 7,
    );
    SensorLevel level(String keyExpr) => SensorLevel(
      time: DateTime.utc(2026, 10, 12, 12),
      keyExpr: keyExpr,
      level: 0.5,
    );
    final gyroLevel = level('sensor/phone/gyro');
    final accelLevel = level('sensor/phone/accel');
    final container = ProviderContainer.test(
      overrides: [
        watchViewModelProvider.overrideWith(
          () => FakeWatchViewModel(
            WatchState(sensors: {'sensor/phone/gyro': gyroLive}),
          ),
        ),
        recentViewModelProvider.overrideWith(
          () => FakeRecentViewModel(
            RecentState(
              byKey: {
                'sensor/phone/gyro': [(sensor: gyroscope, level: gyroLevel)],
                'sensor/phone/accel': [
                  (sensor: accelerometer, level: accelLevel),
                ],
              },
            ),
          ),
        ),
      ],
    );

    // The code to implement: the page's state, from the two.
    final state = container.read(pageViewModelProvider);

    // The claim: the accelerometer's column first, its level and no reading
    // yet, then the gyroscope's, its reading and its level.
    final columns = [
      for (final column in state.columns)
        [column.sensor, column.live, ...column.levels],
    ];
    expect(columns, [
      [accelerometer, null, accelLevel],
      [gyroscope, gyroLive, gyroLevel],
    ]);
  });
}
