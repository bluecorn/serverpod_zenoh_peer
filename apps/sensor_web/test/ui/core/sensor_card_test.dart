import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/ui/core/sensor_card.dart';

/// The texts on screen, in the order they are laid out.
List<String?> _texts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();

/// The reading in these tests, on [keyExpr].
SensorReading _reading(String keyExpr) => SensorReading(
  keyExpr: keyExpr,
  number: 1042,
  x: 0.1,
  y: 9.776,
  z: 0.812,
  time: DateTime.utc(2026, 10, 12, 12, 0, 1, 250),
);

void main() {
  testWidgets("a sensor's card shows its label, its key, each axis with its "
      'unit, and at its foot the stamp, the number and what reached the page', (
    tester,
  ) async {
    // The code to implement: the card of the phone's 1042nd reading of the
    // accelerometer, after 980 reached the page.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorCard(
            latest: _reading('sensor/phone/accel'),
            sensor: accelerometer,
            count: 980,
          ),
        ),
      ),
    );

    // The claim: as the phone's card, its foot with what reached the page.
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
      '1042 readings',
      '980 received here',
    ]);
  });

  testWidgets('the card of a sensor no one has listed is titled with its '
      'segment, with no unit', (tester) async {
    // The code to implement: the card of a reading on a key whose segment the
    // list does not know.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorCard(
            latest: _reading('sensor/phone/baro'),
            sensor: sensorOf('baro'),
            count: 980,
          ),
        ),
      ),
    );

    // The claim: the segment as the title, and each axis without a unit.
    expect(_texts(tester).take(8), [
      'baro',
      'sensor/phone/baro',
      'x',
      '0.100',
      'y',
      '9.776',
      'z',
      '0.812',
    ]);
  });
}
