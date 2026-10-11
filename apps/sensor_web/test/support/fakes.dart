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
