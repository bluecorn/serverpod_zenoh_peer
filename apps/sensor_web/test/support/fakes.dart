import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/ui/page/page_view_model.dart';
import 'package:sensor_web/ui/recent/recent_view_model.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

class FakeWatchViewModel extends WatchViewModel {
  new(this.fixed);

  final WatchState fixed;

  @override
  WatchState build() => fixed;
}

class FakeRecentViewModel extends RecentViewModel {
  new(this.fixed);

  final RecentState fixed;

  @override
  RecentState build() => fixed;
}

/// The web door's endpoint, answering with the streams a test gives it, over a
/// client that never calls the server.
class FakeWebDoor extends EndpointWebDoor {
  new({
    this.readingsStream = const Stream.empty(),
    this.recentStream = const Stream.empty(),
  }) : super(Client('http://localhost:8080/'));

  final Stream<SensorReading> readingsStream;
  final Stream<List<SensorLevel>> recentStream;

  @override
  Stream<SensorReading> readings() => readingsStream;

  @override
  Stream<List<SensorLevel>> recent(int n) => recentStream;
}

class FakePageViewModel extends PageViewModel {
  new(this.fixed);

  final PageState fixed;

  @override
  PageState build() => fixed;
}
