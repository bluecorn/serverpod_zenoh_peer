import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/config/providers.dart';
import 'package:sensor_web/data/repositories/web_door_repository.dart';
import 'package:sensor_web/ui/core/levels_card.dart';
import 'package:sensor_web/ui/core/sensor_card.dart';
import 'package:sensor_web/ui/page/page_screen.dart';

import '../support/fakes.dart';

/// The claim of the page, and the map of what it needs: each expectation, and
/// the test that makes it true. A browser speaks no zenoh, so the page's flow
/// starts at the web door: here the generated client's endpoint is a fake that
/// streams one reading of the accelerometer and the archive's levels of both
/// sensors, and the page is its providers, its repository and its screen. The
/// path from the phone to the web door is the server's flow tests', over real
/// zenoh (`web_door_flow_test.dart`, `numbered_flow_test.dart`); the browser's
/// link to the server is shown by a run.
///
/// 1. The repository hands each reading and each level on with the sensor its
///    key names: "the page's repository hands each reading and each level on
///    with the sensor its key names"
///    (`test/data/repositories/web_door_repository_test.dart`, a fake
///    endpoint).
/// 2. The readings' view model keeps each key's latest reading, its sensor and
///    its count, in the sensor list's order; the levels' view model each key's
///    levels, in the same order: their tests in `test/ui/watch/` and
///    `test/ui/recent/`, fake providers.
/// 3. The page's view model pairs each sensor's latest reading with its levels
///    by their sensor: "the page's view model pairs each sensor's latest
///    reading with its levels, in the sensor list's order"
///    (`test/ui/page/page_view_model_test.dart`, fake view models).
/// 4. A sensor's card and a levels card are the phone's, copied for the web
///    door's models: `test/ui/core/sensor_card_test.dart` and
///    `test/ui/core/levels_card_test.dart`.
/// 5. The page's title bar says "Sensor page" and the route its data takes;
///    a wide browser shows a column per sensor, a narrow one a single column:
///    `test/ui/page/page_screen_test.dart`, a fake view model.
/// 6. The page is called "Sensor page" wherever a browser shows a name, and is
///    themed as the phone is: `main.dart`, `web/index.html` and
///    `web/manifest.json`, shown by the run.
void main() {
  testWidgets('the page shows a column per sensor, its live card above its '
      'levels card, paired by their sensor, and one column when the browser '
      'is narrow', (tester) async {
    // The web door's fake: one reading of the accelerometer, and the
    // archive's levels of both sensors.
    final webDoor = FakeWebDoor(
      readingsStream: Stream.value(
        SensorReading(
          keyExpr: 'sensor/phone/accel',
          number: 1042,
          x: 0.1,
          y: 9.776,
          z: 0.812,
          time: DateTime.utc(2026, 10, 12, 12, 0, 1, 250),
        ),
      ),
      recentStream: Stream.value([
        SensorLevel(
          time: DateTime.utc(2026, 10, 12, 12),
          keyExpr: 'sensor/phone/gyro',
          level: 0.019,
        ),
        SensorLevel(
          time: DateTime.utc(2026, 10, 12, 12),
          keyExpr: 'sensor/phone/accel',
          level: 0.15,
        ),
      ]),
    );
    final container = ProviderContainer.test(
      overrides: [
        webDoorRepositoryProvider.overrideWithValue(WebDoorRepository(webDoor)),
      ],
    );

    // The code to implement: the page, in a wide browser.
    tester.view
      ..physicalSize = const Size(1280, 720)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PageScreen()),
      ),
    );
    await tester.pump();

    // The claim, wide: the accelerometer's column on the left, its live card
    // above its levels card; the gyroscope's on the right, its levels card.
    final live = find.byType(SensorCard);
    final levels = find.byType(LevelsCard);
    expect(live, findsOneWidget);
    expect(levels, findsNWidgets(2));
    expect(tester.widget<SensorCard>(live).sensor, accelerometer);
    expect(tester.widgetList<LevelsCard>(levels).map((card) => card.sensor), [
      accelerometer,
      gyroscope,
    ]);
    expect(tester.getTopLeft(live).dx, tester.getTopLeft(levels.at(0)).dx);
    expect(
      tester.getTopLeft(levels.at(0)).dx,
      lessThan(tester.getTopLeft(levels.at(1)).dx),
    );

    // The code to implement: the same page, in a narrow browser.
    tester.view.physicalSize = const Size(400, 2000);
    await tester.pump();

    // The claim, narrow: one column, the accelerometer's live card above its
    // levels card, above the gyroscope's levels card.
    final tops = [
      tester.getTopLeft(live),
      tester.getTopLeft(levels.at(0)),
      tester.getTopLeft(levels.at(1)),
    ];
    expect(tops.map((top) => top.dx).toSet(), hasLength(1));
    expect(tops[0].dy, lessThan(tops[1].dy));
    expect(tops[1].dy, lessThan(tops[2].dy));
  });
}
