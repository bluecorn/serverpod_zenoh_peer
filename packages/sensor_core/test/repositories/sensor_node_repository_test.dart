import 'dart:async';

import 'package:sensor_core/sensor_core.dart';
import 'package:test/test.dart';
import 'package:zenoh_dart/zenoh.dart';

import '../support/collector.dart';
import '../support/fakes.dart';
import '../support/settings.dart';

void main() {
  test('a sensor reading reaches a subscriber on sensor/phone/accel', () async {
    // The node's end: its session, from the settings that listen.
    final zenoh = ZenohService(sensorNodeSettings());
    addTearDown(zenoh.dispose);
    await zenoh.open();

    // The laptop's end: a witness that subscribes and keeps what arrives, as
    // z_sub does. A plain session, because ZenohService cannot subscribe yet.
    final collector = await openCollector();
    addTearDown(collector.close);
    final subscriber = collector.declareSubscriber('sensor/**');
    addTearDown(subscriber.close);
    final received = <Sample>[];
    subscriber.stream.listen(received.add);
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The code to implement: a repository that publishes one reading
    // from a fake sensor, through the node's session.
    const reading = (x: 0.0, y: 9.776, z: 0.812);
    final sensor = FakeSensorService(Stream.value(reading));
    final repository = SensorNodeRepository(zenoh, sensor, nodeName: 'phone');
    final published = await repository.publish().toList();
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: one sample, on the exact key, as text, marked text/plain,
    // and the reading handed on for the screen with that key.
    final keys = received.map((sample) => sample.keyExpr).toList();
    expect(keys, ['sensor/phone/accel']);
    expect(received.single.payload, '0.000,9.776,0.812');
    expect(received.single.encoding, 'text/plain');
    expect(published.map(_keyAndValues), [
      ('sensor/phone/accel', 0, 9.776, 0.812),
    ]);
  });

  test('a reading is put as x,y,z to three decimals and handed on', () async {
    // Fakes: a service that records what is put through it, and a
    // sensor that delivers one reading.
    final zenoh = FakeZenohService();
    const reading = (x: 0.0, y: 9.776, z: 0.812);
    final sensor = FakeSensorService(Stream.value(reading));

    // The code to implement: each reading put as text, then handed on.
    final repository = SensorNodeRepository(zenoh, sensor, nodeName: 'phone');
    final published = await repository.publish().toList();

    // The claim: the text put through the accelerometer's publication, nothing
    // through the gyroscope's, and the same reading handed on with its key.
    final puts = {for (final p in zenoh.publications) p.keyExpr: p.puts};
    expect(puts, {
      'sensor/phone/accel': ['0.000,9.776,0.812'],
      'sensor/phone/gyro': <String>[],
    });
    expect(published.map(_keyAndValues), [
      ('sensor/phone/accel', 0, 9.776, 0.812),
    ]);
  });

  test('cancelling the stream closes the publication', () async {
    // Fakes: a service that records what is closed, and a sensor that
    // stays quiet, as a real one does between readings.
    final zenoh = FakeZenohService();
    final readings = StreamController<RawReading>();
    final sensor = FakeSensorService(readings.stream);
    final repository = SensorNodeRepository(zenoh, sensor, nodeName: 'phone');

    // The code to implement: a cancel that closes the publications, even
    // while the sensor is quiet.
    final subscription = repository.publish().listen((_) {});
    await subscription.cancel();

    // The claim: both publications the repository declared are closed.
    final closed = zenoh.publications.map((p) => p.isClosed).toList();
    expect(closed, [true, true]);
  });

  test(
    'the phone publishes on sensor/phone/accel and sensor/phone/gyro',
    () async {
      // Fakes: a service that records what is declared on it, and a
      // sensor with nothing to deliver.
      final zenoh = FakeZenohService();
      final sensor = FakeSensorService(const Stream.empty());

      // The code to implement: the repository declares one publication for
      // each sensor.
      final repository = SensorNodeRepository(zenoh, sensor, nodeName: 'phone');
      await repository.publish().toList();

      // The claim: two publications, one on each of the phone's keys.
      final keys = zenoh.publications.map((p) => p.keyExpr).toList();
      expect(keys, ['sensor/phone/accel', 'sensor/phone/gyro']);
    },
  );

  test(
    'a node named sim publishes on sensor/sim/accel and sensor/sim/gyro',
    () async {
      // Fakes: a service that records what is declared on it, and a
      // sensor with nothing to deliver.
      final zenoh = FakeZenohService();
      final sensor = FakeSensorService(const Stream.empty());

      // The code to implement: both keys built from the node's name.
      final repository = SensorNodeRepository(zenoh, sensor, nodeName: 'sim');
      await repository.publish().toList();

      // The claim: two publications, one on each of the sim node's keys.
      final keys = zenoh.publications.map((p) => p.keyExpr).toList();
      expect(keys, ['sensor/sim/accel', 'sensor/sim/gyro']);
    },
  );

  test(
    'a gyroscope reading is put on sensor/phone/gyro and handed on',
    () async {
      // Fakes: a service that records what is put through it, and a sensor
      // whose gyroscope delivers one reading while its accelerometer is quiet.
      final zenoh = FakeZenohService();
      const reading = (x: 0.0, y: 0.0, z: 0.5);
      final sensor = FakeSensorService(
        const Stream.empty(),
        gyroscope: Stream.value(reading),
      );

      // The new contract to implement: the gyroscope read through the sensor
      // service. The code to implement: each of its readings put as text on
      // the gyroscope's key, then handed on.
      final repository = SensorNodeRepository(zenoh, sensor, nodeName: 'phone');
      final published = await repository.publish().toList();

      // The claim: the text put through the gyroscope's publication, nothing
      // through the accelerometer's, and the same reading handed on with its
      // key.
      final puts = {for (final p in zenoh.publications) p.keyExpr: p.puts};
      expect(puts, {
        'sensor/phone/accel': <String>[],
        'sensor/phone/gyro': ['0.000,0.000,0.500'],
      });
      expect(published.map(_keyAndValues), [('sensor/phone/gyro', 0, 0, 0.5)]);
    },
  );

  test('each reading is handed on with its key', () async {
    // Fakes: a service that records what is put through it, and a sensor
    // that delivers one reading of each kind.
    final zenoh = FakeZenohService();
    const accel = (x: 0.0, y: 9.776, z: 0.812);
    const gyro = (x: 0.0, y: 0.0, z: 0.5);
    final sensor = FakeSensorService(
      Stream.value(accel),
      gyroscope: Stream.value(gyro),
    );

    // The code to implement: each reading handed on as a pair, with the key
    // it was put on.
    final repository = SensorNodeRepository(zenoh, sensor, nodeName: 'phone');
    final published = await repository.publish().toList();

    // The claim: each reading handed on under the key it was put on.
    final byKey = {
      for (final (:keyExpr, :reading) in published)
        keyExpr: [reading.x, reading.y, reading.z],
    };
    expect(byKey, {
      'sensor/phone/accel': [0, 9.776, 0.812],
      'sensor/phone/gyro': [0, 0, 0.5],
    });
  });
}

/// A handed-on reading's key and its three values, which the claims compare.
(String, double, double, double) _keyAndValues(KeyedReading published) => (
  published.keyExpr,
  published.reading.x,
  published.reading.y,
  published.reading.z,
);
