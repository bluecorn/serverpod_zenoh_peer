import 'dart:math';

import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/generated/protocol.dart';

/// A level for each key and each second of its readings' own times: the root
/// mean square of their magnitudes around their mean, labelled with the start
/// of the second. A key's second ends when its first reading of a later one
/// arrives; a reading from an earlier second counts in the open one. The
/// readings come from a subscription, so each carries its time.
Stream<SensorLevel> levelsPerSecond(Stream<KeyedReading> readings) {
  final open = <String, ({DateTime start, List<double> magnitudes})>{};
  return readings.expand((keyed) {
    final (:keyExpr, :reading) = keyed;
    final second = _startOfSecond(reading.time!);
    final current = open[keyExpr];
    if (current == null || second.isAfter(current.start)) {
      open[keyExpr] = (start: second, magnitudes: [_magnitude(reading)]);
      return [
        if (current != null)
          SensorLevel(
            time: current.start,
            keyExpr: keyExpr,
            level: _level(current.magnitudes),
          ),
      ];
    }
    current.magnitudes.add(_magnitude(reading));
    return const <SensorLevel>[];
  });
}

DateTime _startOfSecond(DateTime time) => DateTime.fromMillisecondsSinceEpoch(
  time.millisecondsSinceEpoch ~/ 1000 * 1000,
  isUtc: true,
);

double _magnitude(Reading reading) =>
    sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);

double _level(List<double> magnitudes) {
  final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
  final squares = magnitudes.map((m) => (m - mean) * (m - mean));
  return sqrt(squares.reduce((a, b) => a + b) / magnitudes.length);
}
