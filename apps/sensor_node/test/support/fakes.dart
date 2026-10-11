import 'dart:convert';

import 'package:flutter/services.dart';
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
