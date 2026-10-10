import 'package:sensor_core/sensor_core.dart';
import 'package:test/test.dart';

import '../support/collector.dart';
import '../support/fakes.dart';
import '../support/settings.dart';

void main() {
  test('a reading the phone publishes reaches the collector', () async {
    // The node's end: its session, from the settings that listen.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();

    // The laptop's end: a collector's session, from the settings that
    // connect.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();

    // The code to implement: a repository that receives the phone's
    // readings, collected into a list.
    final repository = ReadingsRepository(collectorNode, nodeName: 'phone');
    final received = <KeyedReading>[];
    final listening = repository.readings().listen(received.add);
    addTearDown(listening.cancel);
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The node's code publishes one reading from a fake sensor.
    const reading = Reading(x: 0, y: 9.776, z: 0.812);
    final sensor = FakeSensorService(Stream.value(reading));
    final node = SensorNodeRepository(sensorNode, sensor, nodeName: 'phone');
    await node.publish().toList();
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: one reading arrives, with the three values it left with.
    final values = received
        .map((r) => [r.reading.x, r.reading.y, r.reading.z])
        .toList();
    expect(values, [
      [0, 9.776, 0.812],
    ]);
  });

  test('a payload x,y,z arrives as a reading', () async {
    // A fake: a service whose subscription plays what the test puts into it.
    final zenoh = FakeZenohService();
    final repository = ReadingsRepository(zenoh, nodeName: 'phone');
    final received = <KeyedReading>[];
    final listening = repository.readings().listen(received.add);
    addTearDown(listening.cancel);

    // The code to implement: each payload parsed back into a reading.
    zenoh.subscriptions.single.arrivals.add((
      keyExpr: 'sensor/phone/accel',
      payload: '0.000,9.776,0.812',
      time: DateTime.utc(2026, 10, 10, 12),
    ));
    await pumpEventQueue();

    // The claim: one reading, with the three values of the text.
    final values = received
        .map((r) => [r.reading.x, r.reading.y, r.reading.z])
        .toList();
    expect(values, [
      [0, 9.776, 0.812],
    ]);
  });

  test('cancelling the stream closes the subscription', () async {
    // A fake: a service that records what is closed, whose subscription
    // stays quiet, as a real one does between readings.
    final zenoh = FakeZenohService();
    final repository = ReadingsRepository(zenoh, nodeName: 'phone');

    // The code to implement: a cancel that closes the subscription, even
    // while nothing arrives.
    final listening = repository.readings().listen((_) {});
    await listening.cancel();

    // The claim: the subscription the repository declared is closed.
    expect(zenoh.subscriptions.single.isClosed, isTrue);
  });

  test(
    "the collector receives each of the phone's sensors under its own key",
    () async {
      // The node's end: its session, from the settings that listen.
      final sensorNode = ZenohService(sensorNodeSettings());
      addTearDown(sensorNode.dispose);
      await sensorNode.open();

      // The laptop's end: a collector's session, from the settings that
      // connect.
      final collectorNode = ZenohService(collectorSettings());
      addTearDown(collectorNode.dispose);
      await collectorNode.open();

      // The code to implement: a repository that receives every sensor of the
      // phone, each reading with the key it arrived on, collected into a list.
      final repository = ReadingsRepository(collectorNode, nodeName: 'phone');
      final received = <KeyedReading>[];
      final listening = repository.readings().listen(received.add);
      addTearDown(listening.cancel);
      // The declaration travels to the node, so give it time to arrive.
      await Future<void>.delayed(delivery);

      // The node's code publishes one reading of each sensor from a fake
      // sensor.
      const accel = Reading(x: 0, y: 9.776, z: 0.812);
      const gyro = Reading(x: 0, y: 0, z: 0.5);
      final sensor = FakeSensorService(
        Stream.value(accel),
        gyroscope: Stream.value(gyro),
      );
      final node = SensorNodeRepository(sensorNode, sensor, nodeName: 'phone');
      await node.publish().toList();
      // A put returns before the sample arrives, so give it time to cross.
      await Future<void>.delayed(delivery);

      // The claim: each sensor's reading arrives under that sensor's key.
      final byKey = {
        for (final (:keyExpr, :reading) in received)
          keyExpr: [reading.x, reading.y, reading.z],
      };
      expect(byKey, {
        'sensor/phone/accel': [0, 9.776, 0.812],
        'sensor/phone/gyro': [0, 0, 0.5],
      });
    },
  );

  test('a reading is handed on with the key it arrived on', () async {
    // A fake: a service whose subscription plays what the test puts into it,
    // a sample with its key.
    final zenoh = FakeZenohService();
    final repository = ReadingsRepository(zenoh, nodeName: 'phone');
    final received = <KeyedReading>[];
    final listening = repository.readings().listen(received.add);
    addTearDown(listening.cancel);

    // The code to implement: the key read from the sample, and handed on with
    // the reading.
    zenoh.subscriptions.single.arrivals.add((
      keyExpr: 'sensor/phone/gyro',
      payload: '0.000,0.000,0.500',
      time: DateTime.utc(2026, 10, 10, 12),
    ));
    await pumpEventQueue();

    // The claim: the reading arrives under the key of the sample.
    final byKey = {
      for (final (:keyExpr, :reading) in received)
        keyExpr: [reading.x, reading.y, reading.z],
    };
    expect(byKey, {
      'sensor/phone/gyro': [0, 0, 0.5],
    });
  });

  test('the collector subscribes to sensor/phone/*', () async {
    // A fake: a service that records what is declared on it.
    final zenoh = FakeZenohService();

    // The code to implement: one subscription for every sensor of the phone.
    final repository = ReadingsRepository(zenoh, nodeName: 'phone');
    final listening = repository.readings().listen((_) {});
    addTearDown(listening.cancel);

    // The claim: one subscription, on the expression that matches each of the
    // phone's keys.
    final keys = zenoh.subscriptions.map((s) => s.keyExpr).toList();
    expect(keys, ['sensor/phone/*']);
  });

  test('a collector of the node sim subscribes to sensor/sim/*', () async {
    // A fake: a service that records what is declared on it.
    final zenoh = FakeZenohService();

    // The code to implement: the expression built from the node's name.
    final repository = ReadingsRepository(zenoh, nodeName: 'sim');
    final listening = repository.readings().listen((_) {});
    addTearDown(listening.cancel);

    // The claim: one subscription, on the expression that matches each of the
    // sim node's keys.
    final keys = zenoh.subscriptions.map((s) => s.keyExpr).toList();
    expect(keys, ['sensor/sim/*']);
  });
}
