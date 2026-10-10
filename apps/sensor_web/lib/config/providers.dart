import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/data/repositories/levels_repository.dart';

/// The generated client of the server's endpoints, on the API port of the
/// host that served the page, closed with the container.
final clientProvider = Provider<Client>((ref) {
  final client = Client('http://${Uri.base.host}:8080/');
  ref.onDispose(client.close);
  return client;
});

/// The page's repository: the levels the web door streams.
final levelsRepositoryProvider = Provider<LevelsRepository>(
  (ref) => LevelsRepository(ref.watch(clientProvider)),
);

/// The levels the web door streams, as they arrive.
final levelsProvider = StreamProvider<SensorLevel>(
  (ref) => ref.watch(levelsRepositoryProvider).levels(),
);
