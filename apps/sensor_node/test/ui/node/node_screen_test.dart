import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/core/sensor_card.dart';
import 'package:sensor_node/ui/node/node_screen.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';

import '../../support/fakes.dart';

void main() {
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

  testWidgets('the Live tab shows a card for each key, in the order the keys '
      'arrived', (tester) async {
    // A fake: a view model that holds a fixed state, a reading and a count on
    // each of the phone's two keys.
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

    // The code to implement: the Live tab, built once from that state.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: NodeScreen())),
      ),
    );

    // The claim: a card for each key, in the order of the state, each with
    // its key, its latest reading and its count.
    final cards = tester
        .widgetList<SensorCard>(find.byType(SensorCard))
        .map((card) => (card.keyExpr, card.latest, card.count))
        .toList();
    expect(cards, [
      ('sensor/phone/accel', accel, 42),
      ('sensor/phone/gyro', gyro, 7),
    ]);
  });
}
