import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/ui/core/levels_card.dart';

/// The texts on screen, in the order they are laid out.
List<String?> _texts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();

void main() {
  testWidgets("a levels card shows its sensor's label, what its levels are in "
      "its unit, and each level's second and value, newest first", (
    tester,
  ) async {
    // Two of the accelerometer's levels, newest first.
    SensorLevel level(int second, double value) => SensorLevel(
      time: DateTime.utc(2026, 10, 12, 12, 0, second),
      keyExpr: 'sensor/phone/accel',
      level: value,
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

    // The claim: as the phone's card.
    expect(_texts(tester), [
      'Accelerometer',
      'vibration: spread of the magnitude around its mean, in m/s²',
      '12:00:09',
      '0.183',
      '12:00:08',
      '0.170',
    ]);
  });
}
