import 'dart:async';

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
/// 2. A second's readings on a key give its level, the root mean square of
///    their magnitudes around their mean: `levelsPerSecond`, in
///    `test/domain/levels_test.dart`.
/// 3. Each second gives a level for each key from the readings since the
///    second before, and none for a key that had none: `levelsPerSecond`, in
///    the same file.
/// 4. The seconds are whole seconds, one a second: `ClockService`, in
///    `test/data/services/clock_service_test.dart`.
/// 5. The web door streams the levels to whoever calls it: `LevelsEndpoint`,
///    this test.
/// 6. A browser shows each key's latest level: `sensor_web`'s `LevelsScreen`
///    and `LevelsViewModel`, in its `test/ui/levels/`.
/// 7. A browser reaches the web door: `sensor_web`'s repository over the
///    generated client, which hands the client's stream on unchanged, shown by
///    a run rather than a test.
/// 8. The phone asks each sensor for a reading every 20 ms, a hint that
///    Android may answer faster: `sensor_node`'s `DeviceSensorService`, in its
///    `test/data/services/device_sensor_service_test.dart`.
void main() {
  withServerpod('Given the web door', serverDirectory: serverDirectory, (
    sessionBuilder,
    endpoints,
  ) {
    test(
      "a second of the phone's readings reaches the web door as its vibration "
      'level',
      () async {
        // The phone's end: its session, listening on the loopback.
        final phone = ZenohService(phoneSettings());
        addTearDown(phone.dispose);
        await phone.open();

        // The server's end: its providers, with a session that connects to
        // the phone, and a clock the test moves by hand.
        final seconds = StreamController<DateTime>();
        serverContainer = ProviderContainer.test(
          overrides: [
            configPathProvider.overrideWithValue(serverConfigPath),
            clockServiceProvider.overrideWithValue(
              FakeClockService(seconds.stream),
            ),
          ],
        );
        await serverContainer.read(sessionProvider.future);

        // The code to implement: the web door, called as a browser calls it,
        // its levels collected into a list.
        final received = <SensorLevel>[];
        final listening = endpoints.levels
            .levels(sessionBuilder)
            .listen(received.add);
        addTearDown(listening.cancel);
        // The declaration travels to the phone, so give it time to arrive.
        await Future<void>.delayed(delivery);

        // The phone publishes two accelerometer readings, of magnitudes 5
        // and 10.
        final sensor = FakeSensorService(
          Stream.fromIterable(const [
            Reading(x: 3, y: 4, z: 0),
            Reading(x: 6, y: 8, z: 0),
          ]),
        );
        await SensorNodeRepository(
          phone,
          sensor,
          nodeName: 'phone',
        ).publish().toList();
        // A put returns before the sample arrives, so give it time to cross.
        await Future<void>.delayed(delivery);

        // The second ends.
        final end = DateTime.utc(2026, 10, 10, 12);
        seconds.add(end);
        await pumpEventQueue();

        // The claim: one level, on the accelerometer's key, at the second's
        // end: 5 and 10 lie 2.5 from their mean.
        final levels = received
            .map((level) => (level.time, level.keyExpr, level.level))
            .toList();
        expect(levels, [(end, 'sensor/phone/accel', 2.5)]);
      },
    );
  });
}
