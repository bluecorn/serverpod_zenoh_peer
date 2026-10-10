import 'dart:async';

import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/domain/levels.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test("a second's readings on a key give its level: the root mean square of "
      'their magnitudes around their mean', () async {
    // Readings and seconds that the test puts in by hand.
    final readings = StreamController<KeyedReading>();
    final seconds = StreamController<DateTime>();

    // The code to implement: the levels of what the test puts in, collected
    // into a list.
    final levels = <SensorLevel>[];
    final listening = levelsPerSecond(
      readings.stream,
      seconds: seconds.stream,
    ).listen(levels.add);
    addTearDown(listening.cancel);

    // Five accelerometer readings, of magnitudes 1, 6, 6, 6 and 6, then the
    // second ends.
    const accel = 'sensor/phone/accel';
    for (final reading in const [
      Reading(x: 0, y: 0, z: 1),
      Reading(x: 6, y: 0, z: 0),
      Reading(x: 0, y: 6, z: 0),
      Reading(x: 2, y: 4, z: 4),
      Reading(x: 0, y: 0, z: 6),
    ]) {
      readings.add((keyExpr: accel, reading: reading));
    }
    await pumpEventQueue();
    final end = DateTime.utc(2026, 10, 10, 12);
    seconds.add(end);
    await pumpEventQueue();

    // The claim: one level, at the second's end: the magnitudes lie 4, 1,
    // 1, 1 and 1 from their mean of 5, whose squares average 4.
    final values = levels
        .map((level) => (level.time, level.keyExpr, level.level))
        .toList();
    expect(values, [(end, accel, 2.0)]);
  });
}
