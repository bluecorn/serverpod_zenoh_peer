import 'package:sensor_domain/sensor_domain.dart';

/// One vibration level of a sensor, as the archive keeps it: the sensor, the
/// second it was computed for, and its value.
class Level {
  /// A level of [sensor], of [value], computed for the second starting at
  /// [time].
  const new({required this.sensor, required this.time, required this.value});

  /// The sensor the level is of.
  final Sensor sensor;

  /// The start of the second the level was computed for, in UTC, by the clock
  /// of the session that stamped its readings.
  final DateTime time;

  /// The level itself.
  final double value;
}

/// A level and the key expression it was answered on.
typedef KeyedLevel = ({String keyExpr, Level level});
