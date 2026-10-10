import 'package:riverpod/riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fakes.dart';
import '../support/loopback.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The claim of the web door's live path, and the map of what it needs: each
/// expectation, and the test that makes it true.
///
/// 1. The server receives the phone's readings over zenoh: `sensor_core`'s
///    `ReadingsRepository`, tested there.
/// 2. The web door streams each reading, with its key and its three values,
///    to whoever calls it: `WebDoorEndpoint`, this test.
/// 3. A browser shows each key's latest reading to three decimals and how
///    many have arrived, as the phone's own screen does: `sensor_web`'s
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
    test(
      'a reading the phone publishes reaches the web door with its key and its '
      'three values',
      () async {
        // The phone's end: its session, listening on the loopback.
        final phone = ZenohService(phoneSettings());
        addTearDown(phone.dispose);
        await phone.open();

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

        // The phone publishes one accelerometer reading.
        final sensor = FakeSensorService(
          Stream.value(const Reading(x: 0, y: 9.776, z: 0.812)),
        );
        await SensorNodeRepository(
          phone,
          sensor,
          nodeName: 'phone',
        ).publish().toList();
        // A put returns before the sample arrives, so give it time to cross.
        await Future<void>.delayed(delivery);

        // The claim: one reading, on the accelerometer's key, with the three
        // values it left with.
        final values = received
            .map(
              (reading) => (reading.keyExpr, reading.x, reading.y, reading.z),
            )
            .toList();
        expect(values, [('sensor/phone/accel', 0, 9.776, 0.812)]);
      },
    );
  });
}
