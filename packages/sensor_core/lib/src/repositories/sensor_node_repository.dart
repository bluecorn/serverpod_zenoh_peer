import 'dart:async';

import 'package:sensor_core/src/domain/raw_reading.dart';
import 'package:sensor_core/src/domain/reading.dart';
import 'package:sensor_core/src/services/sensor_service.dart';
import 'package:sensor_core/src/services/zenoh_service.dart';
import 'package:sensor_domain/sensor_domain.dart';

/// The node's side of the readings: it owns the key expressions and publishes
/// what the sensors deliver.
class SensorNodeRepository {
  /// A repository publishing [sensor]'s readings through [zenoh], on the key
  /// expressions of the node called [nodeName].
  new(this.zenoh, this.sensor, {required String nodeName})
    : accelKeyExpr = 'sensor/$nodeName/accel',
      gyroKeyExpr = 'sensor/$nodeName/gyro';

  /// The service the readings are published through.
  final ZenohService zenoh;

  /// The sensor the readings come from.
  final SensorService sensor;

  /// The key expression the accelerometer's readings are published on.
  final String accelKeyExpr;

  /// The key expression the gyroscope's readings are published on.
  final String gyroKeyExpr;

  /// Publishes every reading of each sensor as `x,y,z` to three decimals, on
  /// that sensor's key, and hands each on with its key. Listening declares
  /// the publications; cancelling closes them. The stream ends when both
  /// sensors have ended.
  Stream<KeyedReading> publish() {
    final publications = <Publication>[];
    final subscriptions = <StreamSubscription<RawReading>>[];
    var delivering = 0;
    final controller = StreamController<KeyedReading>();

    void publishOn(String keyExpr, Sensor sensor, Stream<RawReading> readings) {
      final publication = zenoh.declarePublication(keyExpr);
      publications.add(publication);
      delivering += 1;
      subscriptions.add(
        readings.listen(
          (raw) {
            final reading = Reading(
              sensor: sensor,
              x: raw.x,
              y: raw.y,
              z: raw.z,
            );
            publication.put(_asText(reading));
            controller.add((keyExpr: keyExpr, reading: reading));
          },
          onDone: () {
            delivering -= 1;
            if (delivering == 0) {
              unawaited(controller.close());
            }
          },
        ),
      );
    }

    controller
      ..onListen = () {
        publishOn(accelKeyExpr, accelerometer, sensor.accelerometer());
        publishOn(gyroKeyExpr, gyroscope, sensor.gyroscope());
      }
      ..onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        for (final publication in publications) {
          publication.close();
        }
      };
    return controller.stream;
  }

  static String _asText(Reading reading) {
    final x = reading.x.toStringAsFixed(3);
    final y = reading.y.toStringAsFixed(3);
    final z = reading.z.toStringAsFixed(3);
    return '$x,$y,$z';
  }
}
