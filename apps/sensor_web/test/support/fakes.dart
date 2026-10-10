import 'package:sensor_web/ui/watch/watch_view_model.dart';

class FakeWatchViewModel extends WatchViewModel {
  new(this.fixed);

  final WatchState fixed;

  @override
  WatchState build() => fixed;
}
