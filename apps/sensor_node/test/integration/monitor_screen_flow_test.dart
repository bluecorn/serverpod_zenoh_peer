import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/core/levels_card.dart';
import 'package:sensor_node/ui/core/sensor_card.dart';
import 'package:sensor_node/ui/monitor/monitor_screen.dart';

import '../support/loopback.dart';

/// The claim of the monitor's window, and the map of what it needs: each
/// expectation, and the test that makes it true. The phone and the archive
/// are a test double, one session on the loopback that publishes a reading on
/// `sensor/phone/accel` and holds a level of the accelerometer behind a
/// queryable on `archive/phone/**`; the monitor is the app's providers in the
/// monitor role, with a session that connects to it, and its window on
/// screen at the size the Linux runner opens it.
///
/// 1. The monitor's view model pairs each sensor's latest reading with its
///    levels by their sensor, in the sensor list's order: "the monitor's view
///    model pairs each sensor's latest reading with its levels, in the sensor
///    list's order" (`test/ui/monitor/monitor_view_model_test.dart`, fake view
///    models).
/// 2. The window shows a column per sensor, side by side, its live card above
///    its levels card, and says so where a sensor has no reading yet: "the
///    monitor shows a column per sensor, its live card above its levels card"
///    (`test/ui/monitor/monitor_screen_test.dart`, a fake view model).
/// 3. A levels card without levels says so: "a levels card without levels
///    says there are none yet" (`test/ui/core/levels_card_test.dart`).
/// 4. The window's title bar says "Sensor monitor", and beneath it the routes
///    the data takes: "the monitor's title bar names it and the routes its
///    data takes" (`test/ui/monitor/monitor_screen_test.dart`).
/// 5. The live card shows what arrived here, the monitor's readings being
///    received: `NodeViewModel`'s role test and `SensorCard`'s tests, as they
///    are.
/// 6. The monitor role opens this window, and the window's title is "Sensor
///    monitor": `main.dart` and the Linux runner, shown by the run.
void main() {
  testWidgets("in the monitor role, each sensor's column shows its live card "
      'above its levels card, paired by their sensor', (tester) async {
    // The window, at the size the Linux runner opens it.
    tester.view
      ..physicalSize = const Size(1280, 720)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The double of the phone and the archive: a session listening on the
    // loopback, holding one level of the accelerometer behind a queryable.
    final archive = ZenohService(archiveSettings());
    await tester.runAsync(() async {
      await archive.open();
      archive.declareQueryable(
        'archive/phone/**',
        (parameters) => [
          (
            keyExpr: 'archive/phone/accel',
            payload: '2026-10-12T09:00:02.000Z,0.150',
          ),
        ],
      );
    });
    addTearDown(archive.dispose);

    // The code to implement: the monitor's window, in the monitor role, with
    // a session that connects to the double, opened outside the test's fake
    // clock so that its futures belong to the real one.
    final container = ProviderContainer.test(
      overrides: [
        nodeRoleProvider.overrideWithValue(NodeRole.monitor),
        sessionSettingsProvider.overrideWith((ref) => monitorSettings()),
      ],
    );
    await tester.runAsync(() => container.read(sessionProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MonitorScreen()),
      ),
    );
    await _settle(tester);

    // The phone publishes a reading of the accelerometer, and it crosses.
    late final Publication reading;
    await tester.runAsync(() async {
      reading = archive.declarePublication('sensor/phone/accel')
        ..put('1042,0.000,9.776,0.812');
    });
    addTearDown(reading.close);
    await _settle(tester);

    // The claim: one column, the accelerometer's, its live card above its
    // levels card, the live card showing what arrived here.
    final live = find.byType(SensorCard);
    final levels = find.byType(LevelsCard);
    expect(live, findsOneWidget);
    expect(levels, findsOneWidget);
    expect(tester.widget<SensorCard>(live).latest.sensor, accelerometer);
    expect(tester.widget<LevelsCard>(levels).sensor, accelerometer);
    expect(tester.getTopLeft(live).dx, tester.getTopLeft(levels).dx);
    expect(tester.getTopLeft(live).dy, lessThan(tester.getTopLeft(levels).dy));
    expect(find.text('1 received here'), findsOneWidget);
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
