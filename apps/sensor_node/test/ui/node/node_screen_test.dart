import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/node/node_screen.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('the screen shows a block for each key', (tester) async {
    // A fake: a view model that holds a fixed state, with a reading and a
    // count on each of the phone's two keys.
    const accel = Reading(
      sensor: accelerometer,
      number: 42,
      x: 0.1,
      y: 9.776,
      z: 0.812,
    );
    const gyro = Reading(sensor: gyroscope, number: 7, x: 0, y: 0, z: 0.5);
    final container = ProviderContainer.test(
      overrides: [
        nodeViewModelProvider.overrideWith(
          () => FakeNodeViewModel(
            const NodeState(
              sensors: {
                'sensor/phone/accel': SensorState(latest: accel, count: 42),
                'sensor/phone/gyro': SensorState(latest: gyro, count: 7),
              },
            ),
          ),
        ),
      ],
    );

    // The code to implement: the screen, built once from that state, with a
    // block for each key.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NodeScreen()),
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

  testWidgets(
    "the screen shows a reading's time when it has one, and nothing in its "
    'place when it has none',
    (tester) async {
      // A fake: a view model that holds a fixed state, a reading with its
      // time on one key, as a monitor receives it, and one without on the
      // other, as the node publishes it.
      final stamped = Reading(
        sensor: accelerometer,
        number: 42,
        x: 0.1,
        y: 9.776,
        z: 0.812,
        time: DateTime.utc(2026, 10, 10, 12, 0, 1, 250),
      );
      const published = Reading(
        sensor: gyroscope,
        number: 7,
        x: 0,
        y: 0,
        z: 0.5,
      );
      final container = ProviderContainer.test(
        overrides: [
          nodeViewModelProvider.overrideWith(
            () => FakeNodeViewModel(
              NodeState(
                sensors: {
                  'sensor/phone/accel': SensorState(latest: stamped, count: 42),
                  'sensor/phone/gyro': const SensorState(
                    latest: published,
                    count: 7,
                  ),
                },
              ),
            ),
          ),
        ],
      );

      // The code to implement: the screen, built once from that state.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NodeScreen()),
        ),
      );

      // The claim: the one time, in UTC, and no other.
      expect(find.text('12:00:01.250 UTC'), findsOneWidget);
      expect(find.textContaining('UTC'), findsOneWidget);
    },
  );

  testWidgets("the monitor's screen shows the node's number as each key's "
      'count of readings, and how many arrived here', (tester) async {
    // A fake: a view model that holds a fixed state of readings received
    // here, the node's 1042nd reading of the accelerometer after 980 arrived.
    const accel = Reading(
      sensor: accelerometer,
      number: 1042,
      x: 0.1,
      y: 9.776,
      z: 0.812,
    );
    final container = ProviderContainer.test(
      overrides: [
        nodeViewModelProvider.overrideWith(
          () => FakeNodeViewModel(
            const NodeState(
              receives: true,
              sensors: {
                'sensor/phone/accel': SensorState(latest: accel, count: 980),
              },
            ),
          ),
        ),
      ],
    );

    // The code to implement: the screen, built once from that state.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NodeScreen()),
      ),
    );

    // The claim: the node's number as the count of readings, and the
    // monitor's own count as what arrived here.
    expect(find.text('1042 readings'), findsOneWidget);
    expect(find.text('980 received here'), findsOneWidget);
  });

  testWidgets("the phone's screen shows the node's number as each key's count "
      'of readings, and nothing of what arrived', (tester) async {
    // A fake: a view model that holds a fixed state of readings the node
    // publishes, its 42nd of the accelerometer.
    const accel = Reading(
      sensor: accelerometer,
      number: 42,
      x: 0.1,
      y: 9.776,
      z: 0.812,
    );
    final container = ProviderContainer.test(
      overrides: [
        nodeViewModelProvider.overrideWith(
          () => FakeNodeViewModel(
            const NodeState(
              sensors: {
                'sensor/phone/accel': SensorState(latest: accel, count: 42),
              },
            ),
          ),
        ),
      ],
    );

    // The code to implement: the screen, built once from that state.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NodeScreen()),
      ),
    );

    // The claim: the node's number as the count of readings, and no line of
    // what arrived, since the node receives nothing.
    expect(find.text('42 readings'), findsOneWidget);
    expect(find.textContaining('received here'), findsNothing);
  });
}
