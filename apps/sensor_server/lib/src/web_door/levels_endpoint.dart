import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The web door: the phone's vibration levels, for browsers.
class LevelsEndpoint extends Endpoint {
  /// Each key's vibration level, once a second, while the caller listens.
  Stream<SensorLevel> levels(Session session) => const Stream.empty();
}
