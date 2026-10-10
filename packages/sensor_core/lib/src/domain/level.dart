/// One vibration level of a sensor, as the archive keeps it: the second it
/// was computed for, and its value.
class Level {
  /// A level of [value], computed for the second ending at [time].
  const new({required this.time, required this.value});

  /// The end of the second the level was computed for, in UTC, as the server
  /// stamps it.
  final DateTime time;

  /// The level itself.
  final double value;
}

/// A level and the key expression it was answered on.
typedef KeyedLevel = ({String keyExpr, Level level});
