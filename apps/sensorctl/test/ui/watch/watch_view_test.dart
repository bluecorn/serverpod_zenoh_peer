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

  test("watch shows each key's reading with the node's number and its own "
      'count of what it received', () {
    // A state made by the test: on the accelerometer's key, the node's
    // 1042nd reading after 980 received here; on the gyroscope's, the 7th
    // after 7.
    const accel = Reading(
      sensor: accelerometer,
      number: 1042,
      x: 0.1,
      y: 9.776,
      z: 0.812,
    );
    const gyro = Reading(sensor: gyroscope, number: 7, x: 0, y: 0, z: 0.5);
    const state = WatchState(
      sensors: {
        'sensor/phone/accel': SensorState(latest: accel, count: 980),
        'sensor/phone/gyro': SensorState(latest: gyro, count: 7),
      },
    );

    // The code to implement: the lines for that state, one for each key.
    final lines = watchLines(state);

    // The claim: each key, its reading to three decimals, the node's number
    // as its count of readings, and how many were received here, the keys
    // padded so that the readings line up.
    const accelLine =
        'sensor/phone/accel  x   0.100  y   9.776  z   0.812  '
        '1042 readings · 980 received here';
    const gyroLine =
        'sensor/phone/gyro   x   0.000  y   0.000  z   0.500  '
        '7 readings · 7 received here';
    expect(lines, [accelLine, gyroLine]);
  });
}
