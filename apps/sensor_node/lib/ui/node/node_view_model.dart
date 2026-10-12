import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';

/// What the node's screen shows for one key: the latest reading on it, and how
/// many there were.
class SensorState {
  /// A state with [latest] as the newest reading and [count] readings so far.
  const new({required this.latest, required this.count});

  /// The newest reading on the key.
  final Reading latest;

  /// How many readings the node has published on the key, or, in the monitor
  /// role, how many arrived here.
  final int count;
}

/// What the node's screen shows: the state of each key, and whether the
/// readings are received here or published.
class NodeState {
  /// A state with [sensors] as the state of each key, of readings received
  /// here when [receives] is true.
  const new({this.sensors = const {}, this.receives = false});

  /// The state of each key the node has published on, in the order the keys
  /// first arrived.
  final Map<String, SensorState> sensors;

  /// Whether the readings are received here, as the monitor receives them,
  /// rather than published, as the node publishes them.
  final bool receives;
}

/// The view model behind the node's screen, which keeps the latest reading and
/// counts the readings, for each key, and says from the role whether they are
/// received here.
class NodeViewModel extends Notifier<NodeState> {
  @override
  NodeState build() {
    final receives = ref.watch(nodeRoleProvider) == NodeRole.monitor;
    ref.listen(readingsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        final (:keyExpr, :reading) = value;
        final count = state.sensors[keyExpr]?.count ?? 0;
        state = NodeState(
          receives: receives,
          sensors: {
            ...state.sensors,
            keyExpr: SensorState(latest: reading, count: count + 1),
          },
        );
      }
    });
    return NodeState(receives: receives);
  }
}

/// The node screen's view model.
final nodeViewModelProvider = NotifierProvider<NodeViewModel, NodeState>(
  NodeViewModel.new,
);
