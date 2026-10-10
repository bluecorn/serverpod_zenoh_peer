import 'dart:async';

import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/domain/levels.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    "a key's readings in one second give its level, the root mean square of "
    'their magnitudes around their mean, once its next second begins',
    () async {
      // Readings that the test puts in by hand, each with its time.
      final readings = StreamController<KeyedReading>();

      // The code to implement: the levels of what the test puts in, collected
      // into a list.
      final levels = <SensorLevel>[];
      final listening = levelsPerSecond(readings.stream).listen(levels.add);
      addTearDown(listening.cancel);

      // Five accelerometer readings in the second from 12:00:00, of
      // magnitudes 1, 6, 6, 6 and 6, then the first of the next second.
      const accel = 'sensor/phone/accel';
      final second = DateTime.utc(2026, 10, 10, 12);
      final values = [
        (0.0, 0.0, 1.0),
        (6.0, 0.0, 0.0),
        (0.0, 6.0, 0.0),
        (2.0, 4.0, 4.0),
        (0.0, 0.0, 6.0),
      ];
      for (final (i, (x, y, z)) in values.indexed) {
        final time = second.add(Duration(milliseconds: 200 * i));
        readings.add((
          keyExpr: accel,
          reading: Reading(x: x, y: y, z: z, time: time),
        ));
      }
      final next = second.add(const Duration(seconds: 1));
      readings.add((
        keyExpr: accel,
        reading: Reading(x: 0, y: 0, z: 9.81, time: next),
      ));
      await pumpEventQueue();

      // The claim: one level, for the second from 12:00:00: the magnitudes
      // lie 4, 1, 1, 1 and 1 from their mean of 5, whose squares average 4.
      final got = levels
          .map((level) => (level.time, level.keyExpr, level.level))
          .toList();
      expect(got, [(second, accel, 2.0)]);
    },
  );

  test("each key's seconds close on their own, and a key with no readings in a "
      'second gives no level for it', () async {
    // Readings that the test puts in by hand, each with its time.
    final readings = StreamController<KeyedReading>();

    // The code to implement: the levels of what the test puts in, collected
    // into a list.
    final levels = <SensorLevel>[];
    final listening = levelsPerSecond(readings.stream).listen(levels.add);
    addTearDown(listening.cancel);

    // In the second from 12:00:00, magnitudes 5 and 10 on the accelerometer
    // and 1 and 3 on the gyroscope; then 4 and 10 on the accelerometer in
    // the next second, while the gyroscope is silent until the one after.
    const accel = 'sensor/phone/accel';
    const gyro = 'sensor/phone/gyro';
    final first = DateTime.utc(2026, 10, 10, 12);
    void put(String keyExpr, int millis, double x, double y, double z) =>
        readings.add((
          keyExpr: keyExpr,
          reading: Reading(
            x: x,
            y: y,
            z: z,
            time: first.add(Duration(milliseconds: millis)),
          ),
        ));
    put(accel, 100, 3, 4, 0);
    put(gyro, 200, 0, 0, 1);
    put(accel, 500, 6, 8, 0);
    put(gyro, 600, 0, 0, 3);
    put(accel, 1100, 0, 0, 4);
    put(accel, 1500, 0, 0, 10);
    put(gyro, 2100, 0, 0, 1);
    put(accel, 2200, 0, 0, 9.81);
    await pumpEventQueue();

    // The claim: each key's level from its own readings of each second, as
    // its next second begins, and none for the gyroscope's silent second.
    final next = first.add(const Duration(seconds: 1));
    final got = levels
        .map((level) => (level.time, level.keyExpr, level.level))
        .toList();
    expect(got, [(first, accel, 2.5), (first, gyro, 1.0), (next, accel, 3.0)]);
  });
}
