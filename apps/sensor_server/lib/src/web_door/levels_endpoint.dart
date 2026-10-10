import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/domain/levels.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The web door: the phone's vibration levels, for browsers.
class LevelsEndpoint extends Endpoint {
  /// Each key's vibration level, once a second, while the caller listens.
  /// Listening subscribes to the phone's readings; cancelling closes the
  /// subscription.
  Stream<SensorLevel> levels(Session session) => levelsPerSecond(
    serverContainer.read(readingsRepositoryProvider).readings(),
    seconds: serverContainer.read(clockServiceProvider).wholeSeconds(),
  );
}
