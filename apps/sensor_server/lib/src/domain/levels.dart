import 'dart:math';

import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/generated/protocol.dart';

/// A level for each key and each second of its readings' own times: the root
/// mean square of their magnitudes around their mean, labelled with the start
/// of the second. A second ends when the first reading of a later one arrives.
/// The readings come from a subscription, so each carries its time.
Stream<SensorLevel> levelsPerSecond(Stream<KeyedReading> readings) {
  DateTime? start;
  final magnitudes = <double>[];
  return readings.expand((keyed) {
    final (:keyExpr, :reading) = keyed;
    final second = _startOfSecond(reading.time!);
    final open = start;
    if (open != null && second.isAfter(open)) {
      final level = SensorLevel(
        time: open,
        keyExpr: keyExpr,
        level: _level(magnitudes),
      );
      start = second;
      magnitudes
        ..clear()
        ..add(_magnitude(reading));
      return [level];
    }
    start ??= second;
    magnitudes.add(_magnitude(reading));
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
