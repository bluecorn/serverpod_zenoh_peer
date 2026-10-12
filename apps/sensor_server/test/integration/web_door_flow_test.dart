import 'package:riverpod/riverpod.dart';
import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:test/test.dart';
import 'package:zenoh_dart/zenoh.dart';

import '../support/loopback.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The claim of the web door's live path, and the map of what it needs: each
/// expectation, and the test that makes it true.
///
/// 1. The server receives the phone's readings over zenoh, each with the time
///    the phone's session stamped it: `sensor_core`'s `ReadingsRepository`
///    and `ZenohService`, tested there.
/// 2. The web door streams each reading, with its key, its three values and
///    its time, to whoever calls it: `WebDoorEndpoint`, this test.
/// 3. A browser shows each key's latest reading to three decimals, its time
///    and how many have arrived, as the phone's own screen does: `sensor_web`'s
///    `WatchScreen` and `WatchViewModel`, in its `test/ui/watch/`.
/// 4. A browser reaches the web door: `sensor_web`'s repository over the
///    generated client, which hands the client's stream on unchanged, shown by
///    a run rather than a test.
/// 5. The phone asks each sensor for a reading every 20 ms, a hint that
///    Android may answer faster: `sensor_node`'s `DeviceSensorService`, in its
///    `test/data/services/device_sensor_service_test.dart`.
void main() {
  withServerpod('Given the web door', serverDirectory: serverDirectory, (
    sessionBuilder,
    endpoints,
  ) {
    test('a reading the phone publishes reaches the web door with its key, its '
        'three values and the time it was stamped', () async {
      // The phone's end: a plain session listening on the loopback, which
      // stamps what it puts, as the phone's configuration has it do.
      final phone = await Session.open(
        config: Config.fromStr(phoneSettings().json5),
      );
      addTearDown(phone.close);

      // The server's end: its providers, with a session that connects to
      // the phone.
      serverContainer = ProviderContainer.test(
        overrides: [configPathProvider.overrideWithValue(serverConfigPath)],
      );
      await serverContainer.read(sessionProvider.future);

      // The code to implement: the web door, called as a browser calls it,
      // its readings collected into a list.
      final received = <SensorReading>[];
      final listening = endpoints.webDoor
          .readings(sessionBuilder)
          .listen(received.add);
      addTearDown(listening.cancel);
      // The declaration travels to the phone, so give it time to arrive.
      await Future<void>.delayed(delivery);

      // The phone stamps a reading between two readings of the wall clock,
      // and puts it 200 ms later, so the time it arrives is not its stamp.
      final publisher = phone.declarePublisher('sensor/phone/accel');
      addTearDown(publisher.close);
      final before = DateTime.now();
      final stamp = phone.newTimestamp();
      final after = DateTime.now();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      publisher.put('1,0.000,9.776,0.812', timestamp: stamp);
      // A put returns before the sample arrives, so give it time to cross.
      await Future<void>.delayed(delivery);

      // The claim: one reading, on the accelerometer's key, with its three
      // values, and a time between the two readings of the clock.
      final values = received
          .map((reading) => (reading.keyExpr, reading.x, reading.y, reading.z))
          .toList();
      expect(values, [('sensor/phone/accel', 0, 9.776, 0.812)]);
      expect(
        received.single.time.difference(before).inMicroseconds,
        inInclusiveRange(0, after.difference(before).inMicroseconds),
      );
    });
  });
}
