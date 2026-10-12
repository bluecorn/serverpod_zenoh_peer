import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/ui/monitor/monitor_view_model.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

class FakeNodeViewModel extends NodeViewModel {
  new(this.fixed);

  final NodeState fixed;

  @override
  NodeState build() => fixed;
}

class FakeAssetBundle extends AssetBundle {
  new(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(assets[key]!));
}

class FakeRecentViewModel extends RecentViewModel {
  new(this.fixed);

  final RecentState fixed;

  @override
  RecentState build() => fixed;
}

class FakeReadingsRepository implements ReadingsRepository {
  new(this.received);

  final Stream<KeyedReading> received;

  @override
  Stream<KeyedReading> readings() => received;

  @override
  String get keyExpr => 'sensor/phone/*';

  @override
  ZenohService get zenoh => throw UnimplementedError();
}

class FakeSensorNodeRepository implements SensorNodeRepository {
  new(this.published);

  final Stream<KeyedReading> published;
  int publishing = 0;

  @override
  Stream<KeyedReading> publish() {
    publishing += 1;
    return published;
  }

  @override
  String get accelKeyExpr => 'sensor/phone/accel';

  @override
  String get gyroKeyExpr => 'sensor/phone/gyro';

  @override
  SensorService get sensor => throw UnimplementedError();

  @override
  ZenohService get zenoh => throw UnimplementedError();
}

class FakeMonitorViewModel extends MonitorViewModel {
  new(this.fixed);

  final MonitorState fixed;

  @override
  MonitorState build() => fixed;
}
