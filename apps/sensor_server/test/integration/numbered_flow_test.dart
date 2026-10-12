import 'package:riverpod/riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/loopback.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The claim of the node's number, and the map of what it needs: each
/// expectation, and the test that makes it true. The phone is the node's
/// repository over two fake sensors, through a session listening on the
/// loopback; the server is its own providers, with a session that connects to
/// the phone.
///
/// 1. The node numbers each sensor's readings from 1, puts each as
///    `n,x,y,z` and hands it on with its number: "a reading is put as
///    n,x,y,z, numbered from 1 for each sensor, and handed on with its
///    number" (`sensor_core`'s `sensor_node_repository_test.dart`, fakes).
/// 2. A payload `n,x,y,z` arrives as a reading with its number: "a payload
///    n,x,y,z arrives as a reading with its number" (`sensor_core`'s
///    `readings_repository_test.dart`, a fake service).
/// 3. The web door sends each reading with its number: `WebDoorEndpoint`,
///    this test.
/// 4. The monitor's screen shows the node's number as each key's count and,
///    beside it, how many arrived there; the phone's only the number: "the
///    monitor's screen shows the node's number as each key's count of
///    readings, and how many arrived here" and "the phone's screen shows the
///    node's number as each key's count of readings, and nothing of what
///    arrived" (`sensor_node`'s `node_screen_test.dart`, a fake view model).
/// 5. The node's view model says from the role whether its readings are
///    received: "in the monitor role the view model's readings are received,
///    in the node role published" (`sensor_node`'s `node_view_model_test.dart`,
///    fake providers).
/// 6. The page shows the node's number and its own count of what arrived:
///    "the page shows the node's number as each key's count of readings, and
///    how many arrived here" (`sensor_web`'s `watch_screen_test.dart`, a fake
///    view model).
/// 7. `sensorctl`'s line shows the node's number and its own count of what
///    arrived: "watch shows each key's reading with the node's number and its
///    own count of what it received" (its `watch_view_test.dart`).
///
/// The view models already keep each key's latest reading and their own
/// count; the number travels inside the reading, so only the node's changes,
/// for the role.
void main() {
  withServerpod('Given the web door', serverDirectory: serverDirectory, (
    sessionBuilder,
    endpoints,
  ) {
    test('each reading the phone publishes reaches the web door with the '
        'number the phone gave it, counted from 1 for each sensor', () async {
      // The phone's end: a session listening on the loopback.
      final phone = ZenohService(phoneSettings());
      addTearDown(phone.dispose);
      await phone.open();

      // The server's end: its providers, with a session that connects to
      // the phone.
      serverContainer = ProviderContainer.test(
        overrides: [configPathProvider.overrideWithValue(serverConfigPath)],
      );
      await serverContainer.read(sessionProvider.future);

      // The web door, called as a browser calls it, its readings collected
      // into a list.
      final received = <SensorReading>[];
      final listening = endpoints.webDoor
          .readings(sessionBuilder)
          .listen(received.add);
      addTearDown(listening.cancel);
      // The declaration travels to the phone, so give it time to arrive.
      await Future<void>.delayed(delivery);

      // The code to implement: the node's repository publishes two raw
      // readings of the accelerometer and one of the gyroscope, numbering
      // each.
      final node = SensorNodeRepository(phone, _Sensors(), nodeName: 'phone');
      await node.publish().toList();
      // A put returns before the sample arrives, so give it time to cross.
      await Future<void>.delayed(delivery);

      // The claim: each sensor's readings reach the web door numbered from 1,
      // in the order the phone published them.
      final numbers = <String, List<int>>{};
      for (final reading in received) {
        (numbers[reading.keyExpr] ??= []).add(reading.number);
      }
      expect(numbers, {
        'sensor/phone/accel': [1, 2],
        'sensor/phone/gyro': [1],
      });
    });
  });
}

/// The phone's sensors in this test: two raw readings of the accelerometer,
/// one of the gyroscope.
class _Sensors implements SensorService {
  @override
  Stream<RawReading> accelerometer() => Stream.fromIterable([
    (x: 0.0, y: 9.776, z: 0.812),
    (x: 0.1, y: 9.776, z: 0.812),
  ]);

  @override
  Stream<RawReading> gyroscope() => Stream.value((x: 0.0, y: 0.0, z: 0.5));
}
