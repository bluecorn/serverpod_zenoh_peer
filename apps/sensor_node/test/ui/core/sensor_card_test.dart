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

  testWidgets('the card of a sensor no one has listed is titled with its '
      'segment, with no unit', (tester) async {
    // A reading on a key whose segment the list does not know.
    final reading = Reading(
      sensor: sensorOf('baro'),
      number: 7,
      x: 0,
      y: 0,
      z: 0.5,
      time: DateTime.utc(2026, 10, 12, 12, 0, 1, 250),
    );

    // The code to implement: the card of that reading.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorCard(
            keyExpr: 'sensor/phone/baro',
            latest: reading,
            count: 7,
            receives: false,
          ),
        ),
      ),
    );

    // The claim: the segment as the title, and each axis without a unit.
    expect(_texts(tester), [
      'baro',
      'sensor/phone/baro',
      'x',
      '0.000',
      'y',
      '0.000',
      'z',
      '0.500',
      '12:00:01.250 UTC',
      '7 readings',
    ]);
  });

  testWidgets('the card shows how many readings arrived only where they are '
      'received, and the stamp only when there is one', (tester) async {
    // A stamped reading received here, and an unstamped one as the node
    // publishes it.
    final received = Reading(
      sensor: accelerometer,
      number: 1042,
      x: 0.1,
      y: 9.776,
      z: 0.812,
      time: DateTime.utc(2026, 10, 12, 12, 0, 1, 250),
    );
    const published = Reading(sensor: gyroscope, number: 7, x: 0, y: 0, z: 0.5);

    // The code to implement: the two cards, side by side.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SensorCard(
                keyExpr: 'sensor/phone/accel',
                latest: received,
                count: 980,
                receives: true,
              ),
              const SensorCard(
                keyExpr: 'sensor/phone/gyro',
                latest: published,
                count: 7,
                receives: false,
              ),
            ],
          ),
        ),
      ),
    );

    // The claim: the received card's foot holds its stamp, the node's number
    // and what arrived here; the published card's only the node's number.
    final texts = _texts(tester);
    final accel = texts.sublist(0, texts.indexOf('Gyroscope'));
    final gyro = texts.sublist(texts.indexOf('Gyroscope'));
    expect(accel.skip(11), [
      '12:00:01.250 UTC',
      '1042 readings',
      '980 received here',
    ]);
    expect(gyro.skip(11), ['7 readings']);
  });
}
