import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/phone/phone_shell.dart';

import '../support/loopback.dart';

/// The claim of the phone's screens, and the map of what it needs: each
/// expectation, and the test that makes it true. The archive is a test
/// double, one session on the loopback that holds a level behind a queryable
/// on `archive/phone/**` and witnesses what the phone publishes; the phone is
/// the app's providers in the node role over a fake sensor, with a session
/// that connects to the double, and the shell on screen.
///
/// 1. A sensor's card shows its label, its key small beneath, x, y and z on
///    rows of their own with the unit, and the stamp and the node's number at
///    its foot: "a sensor's card shows its label, its key, each axis with its
///    unit, and the stamp and the number at its foot"
///    (`test/ui/core/sensor_card_test.dart`).
/// 2. A sensor no one has listed has a card titled with its segment and no
///    unit: "the card of a sensor no one has listed is titled with its
///    segment, with no unit" (the same file).
/// 3. The card shows how many readings arrived where they are received, and
///    the stamp only when the reading has one: "the card shows how many
///    readings arrived only where they are received, and the stamp only when
///    there is one" (the same file).
/// 4. The Live tab shows a card for each key: "the Live tab shows a card for
///    each key, in the order the keys arrived"
///    (`test/ui/node/node_screen_test.dart`, a fake view model).
/// 5. A levels card shows its sensor's label and unit and its levels, newest
///    first, each its second and value: "a levels card shows its sensor's
///    label and unit, and each level's second and value, newest first"
///    (`test/ui/core/levels_card_test.dart`).
/// 6. The History tab shows a levels card for each sensor, or says there are
///    no levels yet: "the History tab shows a levels card for each key" and
///    "the panel says no levels yet while it has none"
///    (`test/ui/recent/recent_panel_test.dart`, a fake view model).
/// 7. The phone's shell has a title bar, "Sensor node", and the Live and
///    History tabs in a navigation bar at the bottom, History built only when
///    first opened: "the phone's shell shows its title, and the Live and
///    History tabs, building History only when it is opened"
///    (`test/ui/phone/phone_shell_test.dart`, fake view models).
/// 8. The node keeps publishing while History shows: this test.
/// 9. The app is called "Sensor node", on its title bar, in Android's recent
///    apps and under its icon, and is themed from one seed colour, light and
///    dark as the device is: `main.dart` and the manifest, shown by the run.
void main() {
  testWidgets("on the phone, each sensor's card shows its label and unit, and "
      "the History tab the archive's levels, while the node keeps "
      'publishing', (tester) async {
    // The archive's double: a session listening on the loopback, holding one
    // level behind a queryable, and witnessing what the phone publishes.
    final archive = ZenohService(archiveSettings());
    final published = <TimedPayload>[];
    await tester.runAsync(() async {
      await archive.open();
      archive.declareQueryable(
        'archive/phone/**',
        (parameters) => [
          (
            keyExpr: 'archive/phone/accel',
            payload: '2026-10-12T08:00:02.000Z,0.150',
          ),
        ],
      );
      archive
          .declareSubscription('sensor/phone/*')
          .samples
          .listen(published.add);
    });
    addTearDown(archive.dispose);

    // The code to implement: the phone's shell, in the node role, over a
    // fake sensor, with a session that connects to the double.
    final accelerometer = StreamController<RawReading>();
    addTearDown(accelerometer.close);
    final container = ProviderContainer.test(
      overrides: [
        sessionSettingsProvider.overrideWith((ref) => monitorSettings()),
        sensorServiceProvider.overrideWithValue(_Sensors(accelerometer.stream)),
      ],
    );
    // The session opens outside the test's fake clock, before the shell is
    // on screen, so that its futures belong to the real one.
    await tester.runAsync(() => container.read(sessionProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PhoneShell()),
      ),
    );
    // The declarations travel to the double, so give them time to arrive.
    await tester.runAsync(() => Future<void>.delayed(delivery));
    await tester.pump();

    // The phone reads its accelerometer once, and the reading crosses.
    accelerometer.add((x: 0.0, y: 9.776, z: 0.812));
    await _settle(tester);

    // The claim, on the Live tab: the accelerometer's card, with its label and
    // its unit.
    expect(find.text('Accelerometer'), findsOneWidget);
    expect(find.text('m/s²'), findsNWidgets(3));

    // The History tab, opened: it asks the archive, and the answer crosses.
    await tester.tap(find.text('History'));
    await _settle(tester);

    // The claim, on the History tab: the archive's level.
    expect(find.text('0.150'), findsOneWidget);

    // The phone reads its accelerometer again, History on screen.
    final before = published.length;
    accelerometer.add((x: 0.1, y: 9.776, z: 0.812));
    await tester.runAsync(() => Future<void>.delayed(delivery));

    // The claim: the reading still reaches the wire.
    expect(published.length, before + 1);
  });
}

/// Lets real time pass, in steps, pumping after each: the providers' awaits
/// run on the test's fake clock, one step for each pump, and zenoh's answers
/// arrive on the real one.
Future<void> _settle(WidgetTester tester) async {
  for (var step = 0; step < 10; step += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

/// The phone's sensors in this test: the accelerometer the test feeds, a
/// silent gyroscope.
class _Sensors implements SensorService {
  new(this._accelerometer);

  final Stream<RawReading> _accelerometer;

  @override
  Stream<RawReading> accelerometer() => _accelerometer;

  @override
  Stream<RawReading> gyroscope() => const Stream.empty();
}
