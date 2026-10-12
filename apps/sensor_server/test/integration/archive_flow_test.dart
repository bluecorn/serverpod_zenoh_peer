import 'package:riverpod/riverpod.dart';
import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:test/test.dart';
import 'package:zenoh_dart/zenoh.dart';

import '../support/loopback.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The claim of the archive, and the map of what it needs: each expectation,
/// and the test that makes it true.
///
/// 1. The server receives the phone's readings over zenoh, each with the time
///    the phone's session stamped it: `sensor_core`'s `ReadingsRepository`
///    and `ZenohService`, tested there.
/// 2. Each key's readings give a level for each of their own seconds, once
///    the key's next second begins: `levelsPerSecond`, in
///    `test/domain/levels_test.dart`.
/// 3. Each level is kept in the archive as it is made, through one
///    subscription of the recorder's own: `Recorder`, this test.
/// 4. The archive answers its last n levels, newest first:
///    `ArchiveRepository`, this test.
/// 5. The web door's `recent(n)` streams them at once and again each time a
///    level is kept: `WebDoorEndpoint`, this test.
/// 6. A browser shows the last n levels beside the phone's screen, by key:
///    `sensor_web`'s recent-levels panel and its view model, in its
///    `test/ui/recent/`.
/// 7. A browser reaches `recent(n)`, and `run()` starts the recorder once the
///    server has started, through a session of its own with logging off:
///    shown by a run rather than a test.
void main() {
  withServerpod(
    'Given the archive',
    serverDirectory: serverDirectory,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      test("the phone's readings are kept as per-second levels, and the web "
          "door's recent(n) streams the last n, newest first, again as each "
          'level is kept', () async {
        // The phone's end: a plain session listening on the loopback, which
        // stamps what it puts, as the phone's configuration has it do.
        final phone = await Session.open(
          config: Config.fromStr(phoneSettings().json5),
        );
        addTearDown(phone.close);
        final publisher = phone.declarePublisher('sensor/phone/accel');
        addTearDown(publisher.close);
        var number = 0;
        void put(double x, double y, double z) => publisher.put(
          '${number += 1},$x,$y,$z',
          timestamp: phone.newTimestamp(),
        );

        // The server's end: its providers, with a session that connects to
        // the phone, and the recorder started through a session of the
        // test's.
        serverContainer = ProviderContainer.test(
          overrides: [configPathProvider.overrideWithValue(serverConfigPath)],
        );
        await serverContainer.read(sessionProvider.future);
        final recording = serverContainer
            .read(recorderProvider)
            .start(sessionBuilder.build());
        addTearDown(recording.cancel);

        // The code to implement: the web door's last two levels, called as
        // a browser calls it, each list it sends collected.
        final sent = <List<SensorLevel>>[];
        final listening = endpoints.webDoor
            .recent(sessionBuilder, 2)
            .listen(sent.add);
        addTearDown(listening.cancel);
        // The declaration travels to the phone, so give it time to arrive.
        await Future<void>.delayed(delivery);

        // Three seconds of the phone's accelerometer: magnitudes 5 and 10,
        // then 4 and 10, then 1 and 3; a reading in a fourth second closes
        // the third.
        await _untilNextSecond();
        final first = _startOfSecond(DateTime.now());
        put(3, 4, 0);
        put(6, 8, 0);
        await _untilNextSecond();
        put(0, 0, 4);
        put(0, 0, 10);
        await _untilNextSecond();
        put(0, 0, 1);
        put(0, 0, 3);
        await _untilNextSecond();
        put(0, 0, 9.81);
        // A put returns before the sample arrives, so give it time to cross.
        await Future<void>.delayed(delivery);

        // The claim: the last list sent holds the two newest levels, newest
        // first: the third second's, 1 and 3 lying 1 from their mean, and
        // the second's, 4 and 10 lying 3 from theirs.
        final last = sent.last
            .map((level) => (level.time, level.keyExpr, level.level))
            .toList();
        expect(last, [
          (first.add(const Duration(seconds: 2)), 'sensor/phone/accel', 1.0),
          (first.add(const Duration(seconds: 1)), 'sensor/phone/accel', 3.0),
        ]);
      });
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
