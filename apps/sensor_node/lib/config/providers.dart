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

/// The role the app plays.
final nodeRoleProvider = Provider<NodeRole>((ref) => NodeRole.node);

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

/// The session, opened once; what depends on it waits for this.
final sessionProvider = FutureProvider<void>((ref) async {
  final service = await ref.watch(zenohServiceProvider.future);
  await service.open();
});

/// The readings the node publishes, each with its key, once the session is
/// open.
final readingsProvider = StreamProvider<KeyedReading>((ref) async* {
  await ref.watch(sessionProvider.future);
  if (ref.watch(nodeRoleProvider) == NodeRole.monitor) return;
  yield* (await ref.watch(sensorNodeRepositoryProvider.future)).publish();
});
