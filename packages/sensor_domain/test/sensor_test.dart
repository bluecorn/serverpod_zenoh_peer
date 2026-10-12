import 'package:sensor_domain/sensor_domain.dart';
import 'package:test/test.dart';

void main() {
  test('a segment the list knows gives its sensor', () {
    // The code to implement: each sensor looked up by the last segment of the
    // key its readings travel on.
    final found = [sensorOf('accel'), sensorOf('gyro')];

    // The claim: the accelerometer and the gyroscope, each with its label and
    // its unit.
    expect(found, [
      (segment: 'accel', label: 'Accelerometer', unit: 'm/s²'),
      (segment: 'gyro', label: 'Gyroscope', unit: 'rad/s'),
    ]);
  });

  test(
    'a segment the list does not know gives a sensor of its own, labelled with '
    'the segment, with no unit',
    () {
      // The code to implement: a sensor for a key no one has listed, such as a
      // third sensor of a node, so that it is shown rather than lost.
      final found = sensorOf('baro');

      // The claim: its segment, its segment again as the label, and no unit.
      expect(found, (segment: 'baro', label: 'baro', unit: ''));
    },
  );
}
