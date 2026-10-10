import 'package:sensor_web/ui/levels/levels_view_model.dart';
import 'package:sensor_web/ui/watch/watch_view_model.dart';

class FakeLevelsViewModel extends LevelsViewModel {
  new(this.fixed);

  final LevelsState fixed;

  @override
  LevelsState build() => fixed;
}

class FakeWatchViewModel extends WatchViewModel {
  new(this.fixed);

  final WatchState fixed;

  @override
  WatchState build() => fixed;
}
