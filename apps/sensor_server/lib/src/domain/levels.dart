import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/generated/protocol.dart';

/// A level for each key that had readings, at each of [seconds], from the
/// readings that arrived on it since the second before: the root mean square
/// of their magnitudes around their mean.
Stream<SensorLevel> levelsPerSecond(
  Stream<KeyedReading> readings, {
  required Stream<DateTime> seconds,
}) => const Stream.empty();
