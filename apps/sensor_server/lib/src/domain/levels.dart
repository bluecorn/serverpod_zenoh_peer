import 'dart:async';
import 'dart:math';

import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/generated/protocol.dart';

/// A level for each key that had readings, at each of [seconds], from the
/// readings that arrived on it since the second before: the root mean square
/// of their magnitudes around their mean.
Stream<SensorLevel> levelsPerSecond(
  Stream<KeyedReading> readings, {
  required Stream<DateTime> seconds,
}) {
  late final StreamSubscription<KeyedReading> fromReadings;
  late final StreamSubscription<DateTime> fromSeconds;
  final controller = StreamController<SensorLevel>();
  final magnitudes = <String, List<double>>{};
  controller
    ..onListen = () {
      fromReadings = readings.listen((keyed) {
        (magnitudes[keyed.keyExpr] ??= []).add(_magnitude(keyed.reading));
      });
      fromSeconds = seconds.listen((end) {
        for (final MapEntry(key: keyExpr, value: ofKey) in magnitudes.entries) {
          controller.add(
            SensorLevel(time: end, keyExpr: keyExpr, level: _level(ofKey)),
          );
        }
        magnitudes.clear();
      });
    }
    ..onCancel = () async {
      await fromReadings.cancel();
      await fromSeconds.cancel();
    };
  return controller.stream;
}

double _magnitude(Reading reading) =>
    sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);

double _level(List<double> magnitudes) {
  final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
  final squares = magnitudes.map((m) => (m - mean) * (m - mean));
  return sqrt(squares.reduce((a, b) => a + b) / magnitudes.length);
}
