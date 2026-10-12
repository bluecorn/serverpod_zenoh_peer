import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/core/sensor_card.dart';

/// The texts on screen, in the order they are laid out.
List<String?> _texts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();

void main() {
  testWidgets("a sensor's card shows its label, its key, each axis with its "
      'unit, and the stamp and the number at its foot', (tester) async {
    // The node's 42nd reading of the accelerometer, stamped.
    final reading = Reading(
      sensor: accelerometer,
      number: 42,
      x: 0.1,
      y: 9.776,
      z: 0.812,
      time: DateTime.utc(2026, 10, 12, 12, 0, 1, 250),
    );

    // The code to implement: the card of that reading, as the phone shows it.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorCard(
            keyExpr: 'sensor/phone/accel',
            latest: reading,
            count: 42,
            receives: false,
          ),
        ),
      ),
    );

    // The claim: the label, the key, each axis's name, value to three
    // decimals and unit, then the stamp in UTC and the node's number.
    expect(_texts(tester), [
      'Accelerometer',
      'sensor/phone/accel',
      'x',
      '0.100',
      'm/s²',
      'y',
      '9.776',
      'm/s²',
      'z',
      '0.812',
      'm/s²',
      '12:00:01.250 UTC',
      '42 readings',
    ]);
  });
}
