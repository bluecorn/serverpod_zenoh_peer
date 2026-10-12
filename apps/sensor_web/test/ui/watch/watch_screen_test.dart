import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/ui/watch/watch_screen.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets(
    'the page shows a block for each key, with the time its reading was '
    'stamped, as the phone does',
    (tester) async {
      // A fake: a view model that holds a fixed state, with a reading and a
      // count on each of the phone's two keys.
      final accel = SensorReading(
        keyExpr: 'sensor/phone/accel',
        number: 42,
        x: 0.1,
        y: 9.776,
        z: 0.812,
        time: DateTime.utc(2026, 10, 10, 12, 0, 1, 250),
      );
      final gyro = SensorReading(
        keyExpr: 'sensor/phone/gyro',
        number: 7,
        x: 0,
        y: 0,
        z: 0.5,
        time: DateTime.utc(2026, 10, 10, 12, 0, 1, 500),
      );
      final container = ProviderContainer.test(
        overrides: [
          watchViewModelProvider.overrideWith(
            () => FakeWatchViewModel(
              WatchState(
                sensors: {
                  'sensor/phone/accel': SensorState(latest: accel, count: 42),
                  'sensor/phone/gyro': SensorState(latest: gyro, count: 7),
                },
              ),
            ),
          ),
        ],
      );

      // The code to implement: the page, built once from that state, with a
      // block for each key.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: WatchScreen()),
        ),
      );

      // The claim: each key, its reading to three decimals, the time it was
      // stamped, and its count.
      expect(find.text('sensor/phone/accel'), findsOneWidget);
      expect(find.text('x 0.100'), findsOneWidget);
      expect(find.text('y 9.776'), findsOneWidget);
      expect(find.text('z 0.812'), findsOneWidget);
      expect(find.text('12:00:01.250 UTC'), findsOneWidget);
      expect(find.text('42 readings'), findsOneWidget);
      expect(find.text('sensor/phone/gyro'), findsOneWidget);
      expect(find.text('x 0.000'), findsOneWidget);
      expect(find.text('y 0.000'), findsOneWidget);
      expect(find.text('z 0.500'), findsOneWidget);
      expect(find.text('12:00:01.500 UTC'), findsOneWidget);
      expect(find.text('7 readings'), findsOneWidget);
    },
  );

  testWidgets("the page shows the node's number as each key's count of "
      'readings, and how many arrived here', (tester) async {
    // A fake: a view model that holds a fixed state, the node's 1042nd
    // reading of the accelerometer after 980 arrived here.
    final accel = SensorReading(
      keyExpr: 'sensor/phone/accel',
      number: 1042,
      x: 0.1,
      y: 9.776,
      z: 0.812,
      time: DateTime.utc(2026, 10, 12, 8),
    );
    final container = ProviderContainer.test(
      overrides: [
        watchViewModelProvider.overrideWith(
          () => FakeWatchViewModel(
            WatchState(
              sensors: {
                'sensor/phone/accel': SensorState(latest: accel, count: 980),
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
        child: const MaterialApp(home: WatchScreen()),
      ),
    );

    // The claim: the node's number as the count of readings, and the page's
    // own count as what arrived here.
    expect(find.text('1042 readings'), findsOneWidget);
    expect(find.text('980 received here'), findsOneWidget);
  });
}
