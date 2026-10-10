import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_node/data/services/device_sensor_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  test('an accelerometer event becomes a reading, field for field', () async {
    // A fake of the plugin's function: one event, made by the test.
    final event = AccelerometerEvent(0.1, 9.8, 0.2, DateTime(2026, 9, 23, 12));
    final service = DeviceSensorService(
      accelerometerEvents: ({samplingPeriod = SensorInterval.normalInterval}) =>
          Stream.value(event),
    );

    // The code to implement: each event mapped to a reading.
    final readings = await service.accelerometer().toList();

    // The claim: one reading, with the event's values on the three axes.
    final fields = readings.map((r) => (r.x, r.y, r.z)).toList();
    expect(fields, [(0.1, 9.8, 0.2)]);
  });

  test('a gyroscope event becomes a reading, field for field', () async {
    // A fake of the plugin's gyroscope function: one event, made by the test.
    final event = GyroscopeEvent(0.1, 0.2, 0.3, DateTime(2026, 9, 23, 12));
    final service = DeviceSensorService(
      gyroscopeEvents: ({samplingPeriod = SensorInterval.normalInterval}) =>
          Stream.value(event),
    );

    // The code to implement: each gyroscope event mapped to a reading.
    final readings = await service.gyroscope().toList();

    // The claim: one reading, with the event's values on the three axes.
    final fields = readings.map((r) => (r.x, r.y, r.z)).toList();
    expect(fields, [(0.1, 0.2, 0.3)]);
  });

  test(
    'the node asks each sensor for a reading every 20 ms, a hint to Android',
    () async {
      // Fakes of the plugin's two functions, which keep the period each one
      // is asked for.
      final asked = <String, Duration>{};
      final service = DeviceSensorService(
        accelerometerEvents:
            ({samplingPeriod = SensorInterval.normalInterval}) {
              asked['accelerometer'] = samplingPeriod;
              return const Stream.empty();
            },
        gyroscopeEvents: ({samplingPeriod = SensorInterval.normalInterval}) {
          asked['gyroscope'] = samplingPeriod;
          return const Stream.empty();
        },
      );

      // The code to implement: both sensors listened to.
      await service.accelerometer().drain<void>();
      await service.gyroscope().drain<void>();

      // The claim: each sensor asked for a reading every 20 ms.
      expect(asked, {
        'accelerometer': const Duration(milliseconds: 20),
        'gyroscope': const Duration(milliseconds: 20),
      });
    },
  );
}
