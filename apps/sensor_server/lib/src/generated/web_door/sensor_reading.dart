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
import 'package:serverpod/serverpod.dart' as _is;

/// One reading of one of the phone's sensors, as the web door sends it: the key
/// it arrived on, and its value on each of the device's three axes.
abstract class SensorReading
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SensorReading._({
    required this.keyExpr,
    required this.x,
    required this.y,
    required this.z,
  });

  factory SensorReading({
    required String keyExpr,
    required double x,
    required double y,
    required double z,
  }) = _SensorReadingImpl;

  factory SensorReading.fromJson(Map<String, dynamic> jsonSerialization) {
    return SensorReading(
      keyExpr: jsonSerialization['keyExpr'] as String,
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
      z: (jsonSerialization['z'] as num).toDouble(),
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

  /// Returns a shallow copy of this [SensorReading]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SensorReading copyWith({String? keyExpr, double? x, double? y, double? z});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SensorReading',
      'keyExpr': keyExpr,
      'x': x,
      'y': y,
      'z': z,
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
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SensorReadingImpl extends SensorReading {
  _SensorReadingImpl({
    required String keyExpr,
    required double x,
    required double y,
    required double z,
  }) : super._(keyExpr: keyExpr, x: x, y: y, z: z);

  /// Returns a shallow copy of this [SensorReading]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SensorReading copyWith({String? keyExpr, double? x, double? y, double? z}) {
    return SensorReading(
      keyExpr: keyExpr ?? this.keyExpr,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
    );
  }
}
