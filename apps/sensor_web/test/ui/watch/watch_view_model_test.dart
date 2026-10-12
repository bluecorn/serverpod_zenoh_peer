import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/config/providers.dart';
import 'package:sensor_web/domain/sensed.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

void main() {
  test(
    'the view model keeps the latest reading and the count for each key',
    () async {
      // A fake: the readings provider, overridden with three readings on two
      // keys, so nothing below the view model is built.
      final first = SensorReading(
        keyExpr: 'sensor/phone/accel',
        number: 1,
        x: 0,
        y: 9.776,
        z: 0.812,
        time: DateTime.utc(2026, 10, 10, 12),
      );
      final second = SensorReading(
        keyExpr: 'sensor/phone/gyro',
        number: 1,
        x: 0,
        y: 0,
        z: 0.5,
        time: DateTime.utc(2026, 10, 10, 12),
      );
      final third = SensorReading(
        keyExpr: 'sensor/phone/accel',
        number: 2,
        x: 0,
        y: 0,
        z: 9.81,
        time: DateTime.utc(2026, 10, 10, 12),
      );
      final container = ProviderContainer.test(
        overrides: [
          readingsProvider.overrideWith(
            (ref) => Stream.fromIterable([
              (sensor: accelerometer, reading: first),
              (sensor: gyroscope, reading: second),
              (sensor: accelerometer, reading: third),
            ]),
          ),
        ],
      )..listen(watchViewModelProvider, (_, _) {});

      // Let the three readings flow through before reading the state.
      await pumpEventQueue();

      // The code to implement: the view model's state, a latest reading and
      // a count for each key it heard.
      final state = container.read(watchViewModelProvider);

      // The claim: two readings counted on the accelerometer's key and the
      // third kept, one on the gyroscope's.
      final sensors = {
        for (final MapEntry(key: keyExpr, value: sensor)
            in state.sensors.entries)
          keyExpr: (
            latest: (sensor.latest.x, sensor.latest.y, sensor.latest.z),
            count: sensor.count,
          ),
      };
      expect(sensors, {
        'sensor/phone/accel': (latest: (0, 0, 9.81), count: 2),
        'sensor/phone/gyro': (latest: (0, 0, 0.5), count: 1),
      });
    },
  );

  test('the view model orders its keys as the sensor list does, whatever '
      'order they arrive in', () async {
    // A fake: the readings provider, overridden with a reading on an unlisted
    // key, then the gyroscope's, then the accelerometer's.
    SensedReading reading(String keyExpr) => (
      sensor: sensorOf(keyExpr.split('/').last),
      reading: SensorReading(
        keyExpr: keyExpr,
        number: 1,
        x: 0,
        y: 0,
        z: 1,
        time: DateTime.utc(2026, 10, 12, 12),
      ),
    );
    final container = ProviderContainer.test(
      overrides: [
        readingsProvider.overrideWith(
          (ref) => Stream.fromIterable([
            reading('sensor/phone/baro'),
            reading('sensor/phone/gyro'),
            reading('sensor/phone/accel'),
          ]),
        ),
      ],
    )..listen(watchViewModelProvider, (_, _) {});
    await pumpEventQueue();

    // The code to implement: the view model's state.
    final state = container.read(watchViewModelProvider);

    // The claim: the accelerometer's key, the gyroscope's, then the unlisted
    // one.
    expect(state.sensors.keys, [
      'sensor/phone/accel',
      'sensor/phone/gyro',
      'sensor/phone/baro',
    ]);
  });
}
