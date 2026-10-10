import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/ui/watch/watch_screen.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('the page shows a block for each key, as the phone does', (
    tester,
  ) async {
    // A fake: a view model that holds a fixed state, with a reading and a
    // count on each of the phone's two keys.
    final accel = SensorReading(
      keyExpr: 'sensor/phone/accel',
      x: 0.1,
      y: 9.776,
      z: 0.812,
    );
    final gyro = SensorReading(
      keyExpr: 'sensor/phone/gyro',
      x: 0,
      y: 0,
      z: 0.5,
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

    // The claim: each key, its reading to three decimals, and its count.
    expect(find.text('sensor/phone/accel'), findsOneWidget);
    expect(find.text('x 0.100'), findsOneWidget);
    expect(find.text('y 9.776'), findsOneWidget);
    expect(find.text('z 0.812'), findsOneWidget);
    expect(find.text('42 readings'), findsOneWidget);
    expect(find.text('sensor/phone/gyro'), findsOneWidget);
    expect(find.text('x 0.000'), findsOneWidget);
    expect(find.text('y 0.000'), findsOneWidget);
    expect(find.text('z 0.500'), findsOneWidget);
    expect(find.text('7 readings'), findsOneWidget);
  });
}
