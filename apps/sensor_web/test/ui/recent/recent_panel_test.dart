import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/ui/recent/recent_panel.dart';
import 'package:sensor_web/ui/recent/recent_view_model.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets("the panel shows each key's latest levels, newest first", (
    tester,
  ) async {
    // A fake: a view model that holds a fixed state, two levels on the
    // accelerometer's key and one on the gyroscope's.
    SensorLevel level(String keyExpr, int second, double value) => SensorLevel(
      time: DateTime.utc(2026, 10, 11, 0, 50, second),
      keyExpr: keyExpr,
      level: value,
    );
    final container = ProviderContainer.test(
      overrides: [
        recentViewModelProvider.overrideWith(
          () => FakeRecentViewModel(
            RecentState(
              byKey: {
                'sensor/phone/accel': [
                  level('sensor/phone/accel', 3, 0.6),
                  level('sensor/phone/accel', 2, 0.676),
                ],
                'sensor/phone/gyro': [level('sensor/phone/gyro', 3, 0.231)],
              },
            ),
          ),
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

    // The claim: the header, then each key and its levels, newest first, each
    // the second it covers in UTC and the level to three decimals.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(texts, [
      'vibration level, last 20 (UTC)',
      'sensor/phone/accel',
      '00:50:03   0.600',
      '00:50:02   0.676',
      'sensor/phone/gyro',
      '00:50:03   0.231',
    ]);
  });
}
