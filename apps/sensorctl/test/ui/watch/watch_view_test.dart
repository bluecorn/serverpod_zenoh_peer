import 'package:sensor_core/sensor_core.dart';
import 'package:sensorctl/ui/watch/watch_view.dart';
import 'package:sensorctl/ui/watch/watch_view_model.dart';
import 'package:test/test.dart';

void main() {
  test('before the first reading the line says so', () {
    // The state the program starts with: no reading yet.
    const state = WatchState();

    // The code to implement: the lines for that state.
    final lines = watchLines(state);

    // The claim: one line, which says that nothing has arrived.
    expect(lines, ['no readings yet']);
  });

  test('watch shows a line for each key', () {
    // A state with a reading and a count on each of the phone's two keys,
    // made by the test.
    const accel = Reading(
      sensor: accelerometer,
      number: 42,
      x: 0.1,
      y: 9.776,
      z: 0.812,
    );
    const gyro = Reading(sensor: gyroscope, number: 7, x: 0, y: 0, z: 0.5);
    const state = WatchState(
      sensors: {
        'sensor/phone/accel': SensorState(latest: accel, count: 42),
        'sensor/phone/gyro': SensorState(latest: gyro, count: 7),
      },
    );

    // The code to implement: the lines for that state, one for each key.
    final lines = watchLines(state);

    // The claim: each key, its reading to three decimals, and its count, the
    // keys padded so that the readings line up.
    expect(lines, [
      'sensor/phone/accel  x   0.100  y   9.776  z   0.812  42 readings',
      'sensor/phone/gyro   x   0.000  y   0.000  z   0.500  7 readings',
    ]);
  });
}
