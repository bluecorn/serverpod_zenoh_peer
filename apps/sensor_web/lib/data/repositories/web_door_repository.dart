import 'package:sensor_client/sensor_client.dart';

/// The page's side of the web door: what the server streams to browsers.
class WebDoorRepository {
  /// A repository calling the web door through [client].
  new(this.client);

  /// The generated client of the server's endpoints.
  final Client client;

  /// Every reading the phone publishes, with its key. Listening calls the web
  /// door; cancelling ends the call.
  Stream<SensorReading> readings() => client.webDoor.readings();

  /// The archive's last [n] levels, newest first: at once, and again each time
  /// the server keeps a level. Listening calls the web door; cancelling ends
  /// the call.
  Stream<List<SensorLevel>> recent(int n) => client.webDoor.recent(n);
}
