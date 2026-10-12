import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/core/levels_card.dart';

void main() {
  testWidgets("a levels card shows its sensor's label and unit, and each "
      "level's second and value, newest first", (tester) async {
    // Two of the accelerometer's levels, newest first.
    Level level(int second, double value) => Level(
      sensor: accelerometer,
      time: DateTime.utc(2026, 10, 12, 12, 0, second),
      value: value,
    );

    // The code to implement: the card of those levels.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelsCard(
            sensor: accelerometer,
            levels: [level(9, 0.183), level(8, 0.17)],
          ),
        ),
      ),
    );

    // The claim: the label, the unit, then each level's second in UTC and its
    // value to three decimals, in the order given.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(texts, [
      'Accelerometer',
      'm/s²',
      '12:00:09',
      '0.183',
      '12:00:08',
      '0.170',
    ]);
  });

  testWidgets('a levels card without levels says there are none yet', (
    tester,
  ) async {
    // The code to implement: the gyroscope's card, before the archive holds
    // any of its levels.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LevelsCard(sensor: gyroscope, levels: []),
        ),
      ),
    );

    // The claim: the label, the unit, and a line that says so.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(texts, ['Gyroscope', 'rad/s', 'no levels yet']);
  });
}
