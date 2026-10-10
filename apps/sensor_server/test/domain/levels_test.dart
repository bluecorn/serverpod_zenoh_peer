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
}
