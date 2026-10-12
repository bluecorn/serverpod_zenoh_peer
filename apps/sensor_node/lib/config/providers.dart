import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/data/services/device_sensor_service.dart';
import 'package:sensor_node/data/services/settings_asset_service.dart';

/// The two roles of the app: the node, which publishes the phone's sensors,
/// and the monitor, which receives them and shows the archive's levels.
enum NodeRole {
  /// The phone, publishing its sensors.
  node,

  /// The laptop, receiving the phone's readings and the archive's levels.
  monitor,
}

/// The role the build names in `NODE_ROLE` (`node` or `monitor`), or the
/// node when the build names none.
final NodeRole buildRole = NodeRole.values.byName(
  const String.fromEnvironment('NODE_ROLE', defaultValue: 'node'),
);

/// The role the app plays: the build's.
final nodeRoleProvider = Provider<NodeRole>((ref) => buildRole);

/// The name of the session's configuration file under `config/`: the build's
/// `ZENOH_CONFIG`, or `development` when the build names none.
final configNameProvider = Provider<String>(
  (ref) =>
      const String.fromEnvironment('ZENOH_CONFIG', defaultValue: 'development'),
);

/// The service that reads the configuration file.
final settingsAssetServiceProvider = Provider<SettingsAssetService>(
  (ref) => SettingsAssetService(),
);

/// Which side of the topology this app is on, as its configuration file says.
final sessionSettingsProvider = FutureProvider<SessionSettings>(
  (ref) => ref
      .watch(settingsAssetServiceProvider)
      .read(ref.watch(configNameProvider)),
);

/// The app's one zenoh service, made once its settings are read, and disposed
/// with the container.
final zenohServiceProvider = FutureProvider<ZenohService>((ref) async {
  final service = ZenohService(await ref.watch(sessionSettingsProvider.future));
  ref.onDispose(service.dispose);
  return service;
});

/// The device's sensors, behind the interface the core defines.
final sensorServiceProvider = Provider<SensorService>(
  (ref) => DeviceSensorService(),
);

/// The node's repository: this phone's sensors, each on its own key.
final sensorNodeRepositoryProvider = FutureProvider<SensorNodeRepository>(
  (ref) async => SensorNodeRepository(
    await ref.watch(zenohServiceProvider.future),
    ref.watch(sensorServiceProvider),
    nodeName: 'phone',
  ),
);

/// The monitor's repository: the phone's readings, as they arrive.
final readingsRepositoryProvider = FutureProvider<ReadingsRepository>(
  (ref) async => ReadingsRepository(
    await ref.watch(zenohServiceProvider.future),
    nodeName: 'phone',
  ),
);

/// The session, opened once; what depends on it waits for this.
final sessionProvider = FutureProvider<void>((ref) async {
  final service = await ref.watch(zenohServiceProvider.future);
  await service.open();
});

/// The readings the screen shows, each with its key, once the session is
/// open: the ones the node publishes, or in the monitor role the ones it
/// receives. The readings come from the role here, so the monitor never
/// builds the device's sensors; the view model reads the role only to say
/// whether its readings are received, and the screen is the same in both but
/// for the line of what arrived.
final readingsProvider = StreamProvider<KeyedReading>((ref) async* {
  await ref.watch(sessionProvider.future);
  yield* switch (ref.watch(nodeRoleProvider)) {
    NodeRole.node => (await ref.watch(
      sensorNodeRepositoryProvider.future,
    )).publish(),
    NodeRole.monitor => (await ref.watch(
      readingsRepositoryProvider.future,
    )).readings(),
  };
});

/// How many of the archive's levels the monitor's panel shows.
const recentCount = 20;

/// The monitor's repository of the archive's levels: the phone's, asked for
/// through the zenoh door and received as the archive publishes them.
final levelsRepositoryProvider = FutureProvider<LevelsRepository>(
  (ref) async => LevelsRepository(
    await ref.watch(zenohServiceProvider.future),
    nodeName: 'phone',
  ),
);

/// The archive's last [recentCount] levels, newest first, asked for once the
/// session is open.
final recentLevelsProvider = FutureProvider<List<KeyedLevel>>((ref) async {
  await ref.watch(sessionProvider.future);
  final repository = await ref.watch(levelsRepositoryProvider.future);
  return await repository.recent(recentCount);
});

/// Each level the archive publishes as it keeps it, once the session is open.
final liveLevelsProvider = StreamProvider<KeyedLevel>((ref) async* {
  await ref.watch(sessionProvider.future);
  yield* (await ref.watch(levelsRepositoryProvider.future)).live();
});
