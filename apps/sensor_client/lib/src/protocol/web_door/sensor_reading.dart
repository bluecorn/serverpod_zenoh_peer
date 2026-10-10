/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// One reading of one of the phone's sensors, as the web door sends it: the key
/// it arrived on, and its value on each of the device's three axes.
abstract class SensorReading
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SensorReading._({
    required this.keyExpr,
    required this.x,
    required this.y,
    required this.z,
    required this.time,
  });

  factory SensorReading({
    required String keyExpr,
    required double x,
    required double y,
    required double z,
    required DateTime time,
  }) = _SensorReadingImpl;

  factory SensorReading.fromJson(Map<String, dynamic> jsonSerialization) {
    return SensorReading(
      keyExpr: jsonSerialization['keyExpr'] as String,
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
      z: (jsonSerialization['z'] as num).toDouble(),
      time: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['time']),
    );
  }

  /// The key expression the reading arrived on, such as `sensor/phone/accel`.
  String keyExpr;

  /// On the device's x axis, to the right.
  double x;

  /// On the device's y axis, towards the top of the screen.
  double y;

  /// On the device's z axis, out of the screen.
  double z;

  /// When the phone's session stamped the reading, in UTC, or when the server
  /// received it if it carried no stamp.
  DateTime time;

  /// Returns a shallow copy of this [SensorReading]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SensorReading copyWith({
    String? keyExpr,
    double? x,
    double? y,
    double? z,
    DateTime? time,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SensorReading',
      'keyExpr': keyExpr,
      'x': x,
      'y': y,
      'z': z,
      'time': time.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SensorReading',
      'keyExpr': keyExpr,
      'x': x,
      'y': y,
      'z': z,
      'time': time.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _SensorReadingImpl extends SensorReading {
  _SensorReadingImpl({
    required String keyExpr,
    required double x,
    required double y,
    required double z,
    required DateTime time,
  }) : super._(keyExpr: keyExpr, x: x, y: y, z: z, time: time);

  /// Returns a shallow copy of this [SensorReading]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SensorReading copyWith({
    String? keyExpr,
    double? x,
    double? y,
    double? z,
    DateTime? time,
  }) {
    return SensorReading(
      keyExpr: keyExpr ?? this.keyExpr,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      time: time ?? this.time,
    );
  }
}
