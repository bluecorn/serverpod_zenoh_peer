import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

import '../support/loopback.dart';

/// The claim of the native view, and the map of what it needs: each
/// expectation, and the test that makes it true. The phone and the archive
/// are a test double, one session that publishes a reading, holds two levels
/// behind a queryable on `archive/phone/**` and publishes a third as the
/// server does when it keeps one.
///
/// 1. The monitor receives the phone's readings on `sensor/phone/*`, each
///    with the time its publisher stamped: `sensor_core`'s
///    `ReadingsRepository`, tested there ("the collector subscribes to
///    sensor/phone/*", "a reading carries the time of the sample it arrived
///    in").
/// 2. In the monitor role, the screen's readings are the ones the readings
///    repository receives, and nothing is published: "in the monitor role,
///    the screen's readings are the ones received, and nothing is published"
///    (`test/config/providers_test.dart`, fake repositories).
/// 3. In the node role, the screen's readings are still the ones the node
///    publishes: "in the node role, the screen's readings are the ones the
///    node publishes" (`test/config/providers_test.dart`, fake repositories).
/// 4. The node's view model and screen show them unchanged, the time
///    included when a reading has one: `NodeViewModel`'s and `NodeScreen`'s
///    tests, unchanged.
/// 5. The archive's history arrives by one query, with `n`: `sensor_core`'s
///    `LevelsRepository.recent`, tested there.
/// 6. The archive's live levels arrive on a subscription on
///    `archive/<node>/*`: "the levels reader of the node sim listens on
///    archive/sim/*" (`sensor_core`'s `levels_repository_test.dart`, a fake
///    service).
/// 7. Each published `<time>,<level>` arrives as a level under the key it was
///    put on, parsed as the history's replies are: "a published time,value
///    arrives as a level under its key" (the same file).
/// 8. Cancelling the live levels closes their subscription: "cancelling the
///    live levels closes the subscription" (the same file).
/// 9. The panel's view model shows the history, then each published level on
///    top, grouped by key, the keys in the order they first appeared: "the
///    panel's view model shows the history, then each published level on
///    top, the keys in the order they first appeared"
///    (`test/ui/recent/recent_view_model_test.dart`, fake providers).
/// 10. It keeps the newest 20 levels in all keys together: "the panel keeps
///    the newest 20 levels in all, the oldest leaving as a new one arrives"
///    (the same file).
/// 11. The panel shows a header, then each key and its levels newest first,
///    each the second it covers in UTC and the level to three decimals: "the
///    panel shows each key's levels, newest first"
///    (`test/ui/recent/recent_panel_test.dart`, a fake view model).
/// 12. While it has none, it says so: "the panel says no levels yet while it
///    has none" (the same file).
/// 13. The monitor's window lays the screen and the panel side by side, and
///    the monitor skips the node's wakelock: `main.dart`, shown by the Linux
///    build rather than a test, as the browser's page is.
///
/// The providers that ask the levels repository for the history and the live
/// levels are this test's own.
void main() {
  test('in the monitor role, the phone screen shows the readings the phone '
      'publishes, and the panel the levels the archive holds, then the ones '
      'it publishes', () async {
    // The double of the phone and the archive: a session listening on the
    // loopback, holding two levels, newest first, behind a queryable that
    // answers with as many as n asks for.
    final archive = ZenohService(archiveSettings());
    addTearDown(archive.dispose);
    await archive.open();
    const held = [
      (
        keyExpr: 'archive/phone/accel',
        payload: '2026-10-10T12:00:02.000Z,0.150',
      ),
      (
        keyExpr: 'archive/phone/gyro',
        payload: '2026-10-10T12:00:01.000Z,0.019',
      ),
    ];
    final asked = <String?>[];
    archive.declareQueryable('archive/phone/**', (parameters) {
      asked.add(parameters['n']);
      return held.take(int.parse(parameters['n']!));
    });

    // The code to implement: the app's providers in the monitor role, with a
    // session that connects to the double, and the two view models listened
    // to as the window does.
    final container =
        ProviderContainer.test(
            overrides: [
              nodeRoleProvider.overrideWithValue(NodeRole.monitor),
              sessionSettingsProvider.overrideWith((ref) => monitorSettings()),
            ],
          )
          ..listen(nodeViewModelProvider, (_, _) {})
          ..listen(recentViewModelProvider, (_, _) {});
    await container.read(sessionProvider.future);
    // The declarations travel to the double, so give them time to arrive.
    await Future<void>.delayed(delivery);

    // The phone publishes a reading, stamped by its session between two
    // readings of the clock, and the archive publishes a level it keeps.
    final reading = archive.declarePublication('sensor/phone/accel');
    final level = archive.declarePublication('archive/phone/accel');
    final before = DateTime.now();
    reading.put('0.000,9.776,0.812');
    final after = DateTime.now();
    level.put('2026-10-10T12:00:03.000Z,0.183');
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: the screen holds the reading, with a time between the two
    // readings of the clock; the panel asked for 20 levels and holds the
    // published level above the history, by key.
    final node = container.read(nodeViewModelProvider);
    final sensors = {
      for (final MapEntry(key: keyExpr, value: sensor) in node.sensors.entries)
        keyExpr: [sensor.latest.x, sensor.latest.y, sensor.latest.z],
    };
    expect(sensors, {
      'sensor/phone/accel': [0, 9.776, 0.812],
    });
    final time = node.sensors['sensor/phone/accel']!.latest.time!;
    expect(
      time.difference(before).inMicroseconds,
      inInclusiveRange(0, after.difference(before).inMicroseconds),
    );
    expect(asked, ['20']);
    final recent = container.read(recentViewModelProvider);
    final byKey = [
      for (final MapEntry(key: keyExpr, value: levels) in recent.byKey.entries)
        [
          keyExpr,
          levels.map((l) => [l.time.second, l.value]).toList(),
        ],
    ];
    expect(byKey, [
      [
        'archive/phone/accel',
        [
          [3, 0.183],
          [2, 0.150],
        ],
      ],
      [
        'archive/phone/gyro',
        [
          [1, 0.019],
        ],
      ],
    ]);
  });
}
