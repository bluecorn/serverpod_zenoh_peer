import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_web/ui/page/page_screen.dart';
import 'package:sensor_web/ui/page/page_view_model.dart';

import '../../support/fakes.dart';

/// Pumps the page in a browser [width] wide, over a view model that holds
/// [state].
Future<void> _pumpPage(
  WidgetTester tester,
  PageState state, {
  double width = 1280,
}) async {
  tester.view
    ..physicalSize = Size(width, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer.test(
    overrides: [
      pageViewModelProvider.overrideWith(() => FakePageViewModel(state)),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PageScreen()),
    ),
  );
}

void main() {
  testWidgets("the page's title bar names it and the route its data takes", (
    tester,
  ) async {
    // A fake: a view model that holds no columns yet.
    await _pumpPage(tester, const PageState());

    // The claim: the name, and beneath it where the readings and the levels
    // come from.
    final bar = find.byType(AppBar);
    expect(
      find.descendant(of: bar, matching: find.text('Sensor page')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bar,
        matching: find.text("readings and levels through Serverpod's web door"),
      ),
      findsOneWidget,
    );
  });
}
