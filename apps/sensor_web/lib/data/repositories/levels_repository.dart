import 'package:sensor_client/sensor_client.dart';

/// The page's side of the levels: what the web door streams.
class LevelsRepository {
  /// A repository calling the web door through [client].
  new(this.client);

  /// The generated client of the server's endpoints.
  final Client client;

  /// Each key's vibration level, once a second. Listening calls the web door;
  /// cancelling ends the call.
  Stream<SensorLevel> levels() => client.levels.levels();
}
