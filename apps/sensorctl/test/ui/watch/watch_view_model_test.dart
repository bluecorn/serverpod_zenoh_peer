import 'package:riverpod/riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensorctl/config/providers.dart';
import 'package:sensorctl/ui/watch/watch_view_model.dart';
import 'package:test/test.dart';

void main() {
  test(
    'the view model keeps the latest reading and the count for each key',
    () async {
      // A fake: the readings provider, overridden with three readings on two
      // keys, so nothing below the view model is built.
      const first = Reading(sensor: accelerometer, x: 0, y: 9.776, z: 0.812);
      const second = Reading(sensor: gyroscope, x: 0, y: 0, z: 0.5);
      const third = Reading(sensor: accelerometer, x: 0, y: 0, z: 9.81);
      final container = ProviderContainer.test(
        overrides: [
          readingsProvider.overrideWith(
            (ref) => Stream.fromIterable([
              (keyExpr: 'sensor/phone/accel', reading: first),
              (keyExpr: 'sensor/phone/gyro', reading: second),
              (keyExpr: 'sensor/phone/accel', reading: third),
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
}
