import 'package:riverpod/riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/loopback.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The claim of the zenoh door, and the map of what it needs: each
/// expectation, and the test that makes it true.
///
/// 1. The archive keeps each second's levels: the archive's flow test, in
///    `archive_flow_test.dart`.
/// 2. The door answers a `get` on `archive/phone/**` with the archive's last
///    n levels, newest first, each on `archive/phone/<sensor>` as
///    `<time>,<level>`: `ZenohDoor`, this test.
/// 3. The door publishes each level as it is kept, on the same key, in the
///    same form: `ZenohDoor`, this test.
/// 4. A reader asks with n and parses each reply into a level: `sensor_core`'s
///    `LevelsRepository`, tested there.
/// 5. The monitor shows the history and the live levels in its panel:
///    `sensor_node`'s monitor role, tested there.
/// 6. `run()` opens the door once the recorder has started: shown by a run
///    rather than a test.
void main() {
  withServerpod(
    'Given the zenoh door',
    serverDirectory: serverDirectory,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      test(
        "a reader's get on archive/phone/** receives the archive's last n "
        'levels, newest first, and each level kept is published on its key',
        () async {
          // The phone's end: its session, listening on the loopback; it also
          // reads the door, being linked to the server.
          final phone = ZenohService(phoneSettings());
          addTearDown(phone.dispose);
          await phone.open();

          // The server's end: its providers, with a session that connects to
          // the phone, the recorder started and the door opened through a
          // session of the test's.
          serverContainer = ProviderContainer.test(
            overrides: [configPathProvider.overrideWithValue(serverConfigPath)],
          );
          await serverContainer.read(sessionProvider.future);
          final session = sessionBuilder.build();
          final recording = serverContainer
              .read(recorderProvider)
              .start(session);
          addTearDown(recording.cancel);

          // The code to implement: the door, opened over the archive.
          final opened = serverContainer.read(zenohDoorProvider).open(session);
          addTearDown(opened.cancel);

          // Three levels already in the archive.
          final archive = serverContainer.read(archiveRepositoryProvider);
          SensorLevel level(String key, int second, double value) =>
              SensorLevel(
                time: DateTime.utc(2026, 10, 11, 0, 0, second),
                keyExpr: 'sensor/phone/$key',
                level: value,
              );
          await archive.add(session, level('accel', 1, 0.5));
          await archive.add(session, level('gyro', 2, 0.25));
          await archive.add(session, level('accel', 3, 0.75));

          // The phone's end subscribes to the door's live levels.
          final live = <KeyedPayload>[];
          phone
              .declareSubscription('archive/phone/*')
              .samples
              .listen(
                (s) => live.add((keyExpr: s.keyExpr, payload: s.payload)),
              );
          // The declarations travel between the two ends, so give them time.
          await Future<void>.delayed(delivery);

          // The history: the last two levels, asked through the core's
          // repository as a native app asks.
          final history = await LevelsRepository(
            phone,
            nodeName: 'phone',
          ).recent(2);

          // The live part: a second of readings of magnitudes 5 and 10, closed
          // by a reading in the next second, which the recorder keeps as a
          // level of 2.5.
          final readings = phone.declarePublication('sensor/phone/accel');
          await _untilNextSecond();
          final second = _startOfSecond(DateTime.now());
          readings
            ..put('3.0,4.0,0.0')
            ..put('6.0,8.0,0.0');
          await _untilNextSecond();
          readings.put('0.0,0.0,9.81');
          // A put returns before the sample arrives, so give it time to cross.
          await Future<void>.delayed(delivery);

          // The claim: the two newest levels, newest first, each on its
          // archive key; and the kept level published on its key.
          final answered = history
              .map((r) => [r.keyExpr, r.level.time, r.level.value])
              .toList();
          expect(answered, [
            ['archive/phone/accel', DateTime.utc(2026, 10, 11, 0, 0, 3), 0.75],
            ['archive/phone/gyro', DateTime.utc(2026, 10, 11, 0, 0, 2), 0.25],
          ]);
          expect(live, [
            (
              keyExpr: 'archive/phone/accel',
              payload: '${second.toIso8601String()},2.5',
            ),
          ]);
        },
      );
    },
  );
}

/// Waits until 30 ms after the next whole second.
Future<void> _untilNextSecond() {
  final now = DateTime.now();
  final next = DateTime.fromMillisecondsSinceEpoch(
    (now.millisecondsSinceEpoch ~/ 1000 + 1) * 1000 + 30,
  );
  return Future<void>.delayed(next.difference(now));
}

/// The start of the second [time] falls in, in UTC.
DateTime _startOfSecond(DateTime time) => DateTime.fromMillisecondsSinceEpoch(
  time.millisecondsSinceEpoch ~/ 1000 * 1000,
  isUtc: true,
);
