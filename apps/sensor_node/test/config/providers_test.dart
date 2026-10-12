import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';

import '../support/fakes.dart';

void main() {
  test("in the monitor role, the screen's readings are the ones received, and "
      'nothing is published', () async {
    // Fakes: a session that opens at once, a readings repository that
    // receives one reading, and a node repository that would publish
    // another.
    const received = (
      keyExpr: 'sensor/phone/accel',
      reading: Reading(
        sensor: accelerometer,
        number: 1,
        x: 0,
        y: 9.776,
        z: 0.812,
      ),
    );
    const published = (
      keyExpr: 'sensor/phone/gyro',
      reading: Reading(sensor: gyroscope, number: 1, x: 0, y: 0, z: 0.5),
    );
    final node = FakeSensorNodeRepository(Stream.value(published));
    final container = ProviderContainer.test(
      overrides: [
        nodeRoleProvider.overrideWithValue(NodeRole.monitor),
        sessionProvider.overrideWith((ref) async {}),
        readingsRepositoryProvider.overrideWith(
          (ref) => FakeReadingsRepository(Stream.value(received)),
        ),
        sensorNodeRepositoryProvider.overrideWith((ref) => node),
      ],
    );

    // The code to implement: the readings the screen's view model listens
    // to, in the monitor role.
    final readings = <KeyedReading>[];
    container.listen(readingsProvider, (_, next) {
      if (next case AsyncData(:final value)) readings.add(value);
    });
    await pumpEventQueue();

    // The claim: the received reading, and nothing asked of the node's
    // repository.
    expect(readings, [received]);
    expect(node.publishing, 0);
  });

  test(
    "in the node role, the screen's readings are the ones the node publishes",
    () async {
      // Fakes: a session that opens at once, a node repository that publishes
      // one reading, and a readings repository that would receive another.
      const received = (
        keyExpr: 'sensor/phone/accel',
        reading: Reading(
          sensor: accelerometer,
          number: 1,
          x: 0,
          y: 9.776,
          z: 0.812,
        ),
      );
      const published = (
        keyExpr: 'sensor/phone/gyro',
        reading: Reading(sensor: gyroscope, number: 1, x: 0, y: 0, z: 0.5),
      );
      final container = ProviderContainer.test(
        overrides: [
          nodeRoleProvider.overrideWithValue(NodeRole.node),
          sessionProvider.overrideWith((ref) async {}),
          readingsRepositoryProvider.overrideWith(
            (ref) => FakeReadingsRepository(Stream.value(received)),
          ),
          sensorNodeRepositoryProvider.overrideWith(
            (ref) => FakeSensorNodeRepository(Stream.value(published)),
          ),
        ],
      );

      // The code to implement: the readings the screen's view model listens
      // to, in the node role.
      final readings = <KeyedReading>[];
      container.listen(readingsProvider, (_, next) {
        if (next case AsyncData(:final value)) readings.add(value);
      });
      await pumpEventQueue();

      // The claim: the published reading, and not the received one.
      expect(readings, [published]);
    },
  );
}
