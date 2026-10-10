import 'package:riverpod/riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/data/services/clock_service.dart';
import 'package:sensor_server/src/data/services/settings_file_service.dart';

/// The server's providers, held here for its endpoints, which Serverpod builds
/// with no constructor arguments: `run()` fills it, and a test fills it with
/// overrides.
late ProviderContainer serverContainer;

/// The path of the session's configuration file, from the workspace root.
final configPathProvider = Provider<String>(
  (ref) => 'apps/sensor_server/config/zenoh.json5',
);

/// The service that reads the configuration file.
final settingsFileServiceProvider = Provider<SettingsFileService>(
  (ref) => SettingsFileService(),
);

/// Which side of the topology the server is on, as its configuration file
/// says.
final sessionSettingsProvider = Provider<SessionSettings>(
  (ref) => ref
      .watch(settingsFileServiceProvider)
      .read(ref.watch(configPathProvider)),
);

/// The server's one zenoh service, disposed with the container.
final zenohServiceProvider = Provider<ZenohService>((ref) {
  final service = ZenohService(ref.watch(sessionSettingsProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// The session, opened once; the server starts after it.
final sessionProvider = FutureProvider<void>(
  (ref) => ref.watch(zenohServiceProvider).open(),
);

/// The phone's readings, on `sensor/phone/*`.
final readingsRepositoryProvider = Provider<ReadingsRepository>(
  (ref) =>
      ReadingsRepository(ref.watch(zenohServiceProvider), nodeName: 'phone'),
);

/// The clock the levels are timed by.
final clockServiceProvider = Provider<ClockService>((ref) => ClockService());
