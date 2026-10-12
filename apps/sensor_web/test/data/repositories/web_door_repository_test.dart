import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/data/repositories/web_door_repository.dart';

import '../../support/fakes.dart';

void main() {
  test("the page's repository hands each reading and each level on with the "
      'sensor its key names', () async {
    // A fake: the web door's endpoint, streaming a reading of the gyroscope
    // and one list of levels, the accelerometer's and the gyroscope's.
    final time = DateTime.utc(2026, 10, 12, 12);
    final repository = WebDoorRepository(
      FakeWebDoor(
        readingsStream: Stream.value(
          SensorReading(
            keyExpr: 'sensor/phone/gyro',
            number: 1,
            x: 0,
            y: 0,
            z: 1,
            time: time,
          ),
        ),
        recentStream: Stream.value([
          SensorLevel(time: time, keyExpr: 'sensor/phone/accel', level: 0.5),
          SensorLevel(time: time, keyExpr: 'sensor/phone/gyro', level: 0.1),
        ]),
      ),
    );

    // The code to implement: the readings and the levels, each with the
    // sensor the last segment of its key names.
    final readings = await repository.readings().toList();
    final levels = await repository.recent(20).toList();

    // The claim: the reading of the gyroscope; the levels of the
    // accelerometer and the gyroscope, in the order sent.
    expect(readings.map((r) => r.sensor), [gyroscope]);
    expect(levels.single.map((l) => l.sensor), [accelerometer, gyroscope]);
  });
}
