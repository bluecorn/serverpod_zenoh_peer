import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/data/repositories/web_door_repository.dart';
import 'package:sensor_web/domain/sensed.dart';

/// The generated client of the server's endpoints, on the API port of the
/// host that served the page, closed with the container.
final clientProvider = Provider<Client>((ref) {
  final client = Client('http://${Uri.base.host}:8080/');
  ref.onDispose(client.close);
  return client;
});

/// The page's repository: what the web door streams.
final webDoorRepositoryProvider = Provider<WebDoorRepository>(
  (ref) => WebDoorRepository(ref.watch(clientProvider).webDoor),
);

/// The readings the web door streams, each with its sensor, as they arrive.
final readingsProvider = StreamProvider<SensedReading>(
  (ref) => ref.watch(webDoorRepositoryProvider).readings(),
);

/// How many of the archive's levels the page shows.
const recentCount = 20;

/// The archive's latest levels, newest first, each with its sensor, each list
/// the web door sends.
final recentLevelsProvider = StreamProvider<List<SensedLevel>>(
  (ref) => ref.watch(webDoorRepositoryProvider).recent(recentCount),
);
