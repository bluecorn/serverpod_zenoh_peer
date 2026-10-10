import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/ui/levels/levels_screen.dart';
import 'package:sensor_web/ui/levels/levels_view_model.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets(
    "the page shows each key's latest level, to three decimals, at its second",
    (tester) async {
      // A fake: a view model that holds a fixed state, with a level on each
      // of the phone's two keys.
      final second = DateTime.utc(2026, 10, 10, 12, 0, 1);
      final container = ProviderContainer.test(
        overrides: [
          levelsViewModelProvider.overrideWith(
            () => FakeLevelsViewModel(
              LevelsState(
                latest: {
                  'sensor/phone/accel': SensorLevel(
                    time: second,
                    keyExpr: 'sensor/phone/accel',
                    level: 2.5,
                  ),
                  'sensor/phone/gyro': SensorLevel(
                    time: second,
                    keyExpr: 'sensor/phone/gyro',
                    level: 0.0625,
                  ),
                },
              ),
            ),
          ),
        ],
      );

      // The code to implement: the page, built once from that state.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LevelsScreen()),
        ),
      );

      // The claim: each key, its level to three decimals, and the second it
      // was measured over, in UTC.
      expect(find.text('sensor/phone/accel'), findsOneWidget);
      expect(find.text('2.500'), findsOneWidget);
      expect(find.text('sensor/phone/gyro'), findsOneWidget);
      expect(find.text('0.063'), findsOneWidget);
      expect(find.text('12:00:01 UTC'), findsNWidgets(2));
    },
  );
}
