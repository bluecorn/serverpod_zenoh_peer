import 'package:sensor_core/sensor_core.dart';
import 'package:test/test.dart';

import '../support/collector.dart';
import '../support/fakes.dart';
import '../support/settings.dart';

/// The claim of the sensor in the domain, and the map of what it needs: each
/// expectation, and the test that makes it true. The phone is the node's
/// repository over a fake sensor; the archive is the node's own session,
/// publishing a level as the server does when it keeps one; the monitor is a
/// collector's session, through the readings and the levels repositories.
///
/// 1. A segment the list knows gives its sensor: "a segment the list knows
///    gives its sensor" (`sensor_domain`'s `test/sensor_test.dart`).
/// 2. A segment the list does not know gives a sensor of its own, labelled
///    with the segment, with no unit: "a segment the list does not know gives
///    a sensor of its own, labelled with the segment, with no unit" (the same
///    file).
/// 3. The node makes each raw reading a reading of the sensor it came from,
///    and hands it on, for the phone's own screen: "each raw reading is handed
///    on as a reading of the sensor it came from"
///    (`test/repositories/sensor_node_repository_test.dart`, fakes).
/// 4. A reading arrives with the sensor its key names: "a reading arrives with
///    the sensor its key names"
///    (`test/repositories/readings_repository_test.dart`, a fake service).
/// 5. A level, answered or published, arrives with the sensor its key names:
///    "a level, answered or published, carries the sensor its key names"
///    (`test/repositories/levels_repository_test.dart`, a fake service).
/// 6. The node's keys are built from its name and each sensor's segment: "the
///    phone publishes on sensor/phone/accel and sensor/phone/gyro" and "a
///    node named sim publishes on sensor/sim/accel and sensor/sim/gyro" (the
///    node repository's file), unchanged.
/// 7. The device delivers raw readings, field for field: `sensor_node`'s
///    `DeviceSensorService` tests, unchanged.
///
/// The page attaches the sensor in its own repository, from each model's key,
/// with the page's screen (step (e)), where a view first shows it.
void main() {
  test('a reading the phone publishes and a level the archive publishes each '
      "carry their sensor's label and unit, at both ends", () async {
    // The phone's end, which is also the archive's double: a session from
    // the settings that listen.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();

    // The monitor's end: a collector's session, from the settings that
    // connect, receiving readings and levels through the two repositories.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();
    final readings = <KeyedReading>[];
    final levels = <KeyedLevel>[];
    final receiving = ReadingsRepository(
      collectorNode,
      nodeName: 'phone',
    ).readings().listen(readings.add);
    addTearDown(receiving.cancel);
    final archived = LevelsRepository(
      collectorNode,
      nodeName: 'phone',
    ).live().listen(levels.add);
    addTearDown(archived.cancel);
    // The declarations travel to the node, so give them time to arrive.
    await Future<void>.delayed(delivery);

    // The code to implement: the node's repository publishes one raw reading
    // of the accelerometer, and the archive's double publishes a level of
    // the gyroscope.
    final sensor = FakeSensorService(
      Stream.value((x: 0.0, y: 9.776, z: 0.812)),
    );
    final node = SensorNodeRepository(sensorNode, sensor, nodeName: 'phone');
    final published = await node.publish().toList();
    final archive = sensorNode.declarePublication('archive/phone/gyro');
    addTearDown(archive.close);
    archive.put('2026-10-12T07:00:00.000Z,0.019');
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: the reading carries the accelerometer's label and unit as
    // the phone hands it on and as the monitor receives it, and the level
    // the gyroscope's.
    (String, String) labelAndUnit(Sensor sensor) => (sensor.label, sensor.unit);
    expect(published.map((p) => labelAndUnit(p.reading.sensor)), [
      ('Accelerometer', 'm/s²'),
    ]);
    expect(readings.map((r) => labelAndUnit(r.reading.sensor)), [
      ('Accelerometer', 'm/s²'),
    ]);
    expect(levels.map((l) => labelAndUnit(l.level.sensor)), [
      ('Gyroscope', 'rad/s'),
    ]);
  });
}
