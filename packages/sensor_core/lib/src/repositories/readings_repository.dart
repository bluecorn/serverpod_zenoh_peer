import 'dart:async';

import 'package:sensor_core/src/domain/reading.dart';
import 'package:sensor_core/src/services/zenoh_service.dart';
import 'package:sensor_domain/sensor_domain.dart';

/// The collector's side of the readings: it owns the key expression and turns
/// what arrives back into readings.
class ReadingsRepository {
  /// A repository receiving, through [zenoh], the readings of every sensor of
  /// the node called [nodeName].
  new(this.zenoh, {required String nodeName}) : keyExpr = 'sensor/$nodeName/*';

  /// The service the readings arrive through.
  final ZenohService zenoh;

  /// The key expression the subscription is declared on: one segment for the
  /// sensor, so it matches each of the node's keys.
  final String keyExpr;

  /// Every reading that arrives, parsed from `x,y,z`, with the key it arrived
  /// on and its sample's time. Listening declares the subscription;
  /// cancelling closes it.
  Stream<KeyedReading> readings() {
    late final Subscription subscription;
    late final StreamSubscription<TimedPayload> listening;
    final controller = StreamController<KeyedReading>();
    controller.onListen = () {
      subscription = zenoh.declareSubscription(keyExpr);
      listening = subscription.samples.listen(
        (sample) => controller.add((
          keyExpr: sample.keyExpr,
          reading: _asReading(sample.payload, sample.time),
        )),
      );
    };
    controller.onCancel = () async {
      await listening.cancel();
      subscription.close();
    };
    return controller.stream;
  }

  /// A sensor no reading is of yet.
  static const Sensor _none = (segment: '', label: '', unit: '');

  static Reading _asReading(String text, DateTime time) {
    final [x, y, z] = text.split(',').map(double.parse).toList();
    return Reading(sensor: _none, x: x, y: y, z: z, time: time);
  }
}
