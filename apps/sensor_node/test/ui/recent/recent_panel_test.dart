import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/core/levels_card.dart';
import 'package:sensor_node/ui/recent/recent_panel.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('the panel says no levels yet while it has none', (tester) async {
    // A fake: a view model that holds no levels, as before the archive
    // answers.
    final container = ProviderContainer.test(
      overrides: [
        recentViewModelProvider.overrideWith(
          () => FakeRecentViewModel(const RecentState()),
        ),
      ],
    );

    // The code to implement: the panel, built once from that state.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: RecentPanel())),
      ),
    );

    // The claim: the header, then the line that says there are none yet.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(texts, ['vibration level, last 20 (UTC)', 'no levels yet']);
  });

  testWidgets('the History tab shows its heading and a levels card for each '
      'key', (tester) async {
    // A fake: a view model that holds a fixed state, two levels on the
    // accelerometer's key and one on the gyroscope's.
    Level level(Sensor sensor, int second, double value) => Level(
      sensor: sensor,
      time: DateTime.utc(2026, 10, 12, 12, 0, second),
      value: value,
    );
    final accel = [level(accelerometer, 3, 0.6), level(accelerometer, 2, 0.7)];
    final gyro = [level(gyroscope, 3, 0.231)];
    final container = ProviderContainer.test(
      overrides: [
        recentViewModelProvider.overrideWith(
          () => FakeRecentViewModel(
            RecentState(
              byKey: {'archive/phone/accel': accel, 'archive/phone/gyro': gyro},
            ),
          ),
        ),
      ],
    );

    // The code to implement: the History tab, built once from that state.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: RecentPanel())),
      ),
    );

    // The claim: the heading, then a card for each key, in the order of the
    // state, each of its sensor and with its levels.
    expect(find.text('Vibration level, per second (UTC)'), findsOneWidget);
    final cards = tester
        .widgetList<LevelsCard>(find.byType(LevelsCard))
        .map((card) => (card.sensor, card.levels))
        .toList();
    expect(cards, [(accelerometer, accel), (gyroscope, gyro)]);
  });
}
