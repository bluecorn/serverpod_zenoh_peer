import 'package:sensor_web/ui/levels/levels_view_model.dart';

class FakeLevelsViewModel extends LevelsViewModel {
  new(this.fixed);

  final LevelsState fixed;

  @override
  LevelsState build() => fixed;
}
