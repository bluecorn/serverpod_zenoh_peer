/// One reading of a sensor: its value on each of the device's three axes, and
/// when it was published, once a subscriber has received it.
class Reading {
  /// A reading of [x], [y] and [z], published at [time] when that is known.
  const new({required this.x, required this.y, required this.z, this.time});

  /// On the device's x axis, to the right.
  final double x;

  /// On the device's y axis, towards the top of the screen.
  final double y;

  /// On the device's z axis, out of the screen.
  final double z;

  /// When the reading was published, as its subscriber received it: the
  /// zenoh timestamp its publisher's session stamped, or the time it arrived
  /// when it carried none. Null on the publishing side.
  final DateTime? time;
}

/// A reading and the key expression it travels on.
typedef KeyedReading = ({String keyExpr, Reading reading});
