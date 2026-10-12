import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/ui/core/levels_card.dart';
import 'package:sensor_web/ui/core/sensor_card.dart';
import 'package:sensor_web/ui/page/page_screen.dart';
import 'package:sensor_web/ui/page/page_view_model.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

import '../../support/fakes.dart';

/// Pumps the page in a browser [width] wide, over a view model that holds
/// [state].
Future<void> _pumpPage(
  WidgetTester tester,
  PageState state, {
  double width = 1280,
}) async {
  tester.view
    ..physicalSize = Size(width, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer.test(
    overrides: [
      pageViewModelProvider.overrideWith(() => FakePageViewModel(state)),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PageScreen()),
    ),
  );
}

/// A column of [sensor], on [keyExpr], with a reading when [live] is true and
/// [levels] levels.
PageColumn _column(
  Sensor sensor,
  String keyExpr, {
  bool live = true,
  int levels = 0,
}) => PageColumn(
  sensor: sensor,
  live: live
      ? SensorState(
          latest: SensorReading(
            keyExpr: keyExpr,
            number: 42,
            x: 0,
            y: 0,
            z: 1,
            time: DateTime.utc(2026, 10, 12, 12),
          ),
          sensor: sensor,
          count: 40,
        )
      : null,
  levels: [
    for (var second = levels; second > 0; second -= 1)
      SensorLevel(
        time: DateTime.utc(2026, 10, 12, 12, 0, second),
        keyExpr: keyExpr,
        level: 0.5,
      ),
  ],
);

void main() {
  testWidgets("the page's title bar names it and the route its data takes", (
    tester,
  ) async {
    // A fake: a view model that holds no columns yet.
    await _pumpPage(tester, const PageState());

    // The claim: the name, and beneath it where the readings and the levels
    // come from.
    final bar = find.byType(AppBar);
    expect(
      find.descendant(of: bar, matching: find.text('Sensor page')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bar,
        matching: find.text("readings and levels through Serverpod's web door"),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a wide browser shows a column per sensor, its live card above '
      'its levels card', (tester) async {
    // A fake: the accelerometer's column, a reading and two levels, and the
    // gyroscope's, a reading and no levels yet.
    await _pumpPage(
      tester,
      PageState(
        columns: [
          _column(accelerometer, 'sensor/phone/accel', levels: 2),
          _column(gyroscope, 'sensor/phone/gyro'),
        ],
      ),
    );

    // The claim: two columns side by side, the accelerometer's on the left,
    // each its live card above its levels card.
    final live = find.byType(SensorCard);
    final levels = find.byType(LevelsCard);
    expect(live, findsNWidgets(2));
    expect(levels, findsNWidgets(2));
    expect(tester.widgetList<SensorCard>(live).map((card) => card.sensor), [
      accelerometer,
      gyroscope,
    ]);
    final lefts = [
      for (var i = 0; i < 2; i += 1) tester.getTopLeft(live.at(i)),
    ];
    expect(lefts[0].dx, lessThan(lefts[1].dx));
    for (var i = 0; i < 2; i += 1) {
      expect(tester.getTopLeft(levels.at(i)).dx, lefts[i].dx);
      expect(tester.getTopLeft(levels.at(i)).dy, greaterThan(lefts[i].dy));
    }
  });

  testWidgets('a browser narrower than 720 shows one column, each sensor its '
      'live card before its levels card', (tester) async {
    // A fake: the accelerometer's column and the gyroscope's, each a reading
    // and a level, in a browser 400 wide.
    await _pumpPage(
      tester,
      PageState(
        columns: [
          _column(accelerometer, 'sensor/phone/accel', levels: 1),
          _column(gyroscope, 'sensor/phone/gyro', levels: 1),
        ],
      ),
      width: 400,
    );

    // The claim: the four cards one under the other, in one column: the
    // accelerometer's live card, its levels card, then the gyroscope's.
    final cards = find.byWidgetPredicate(
      (widget) => widget is SensorCard || widget is LevelsCard,
    );
    final order = [
      for (final widget in tester.widgetList(cards))
        switch (widget) {
          SensorCard(:final sensor) => ('live', sensor.segment),
          LevelsCard(:final sensor) => ('levels', sensor.segment),
          _ => ('other', ''),
        },
    ];
    expect(order, [
      ('live', 'accel'),
      ('levels', 'accel'),
      ('live', 'gyro'),
      ('levels', 'gyro'),
    ]);
    final tops = [
      for (var i = 0; i < 4; i += 1) tester.getTopLeft(cards.at(i)),
    ];
    expect(tops.map((top) => top.dx).toSet(), hasLength(1));
    for (var i = 1; i < 4; i += 1) {
      expect(tops[i].dy, greaterThan(tops[i - 1].dy));
    }
  });
}
