import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_node/ui/node/node_screen.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';
import 'package:sensor_node/ui/phone/phone_shell.dart';
import 'package:sensor_node/ui/recent/recent_panel.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets("the phone's shell shows its title, and the Live and History "
      'tabs, building History only when it is opened', (tester) async {
    // Fakes: the two view models, each holding nothing.
    final container = ProviderContainer.test(
      overrides: [
        nodeViewModelProvider.overrideWith(
          () => FakeNodeViewModel(const NodeState()),
        ),
        recentViewModelProvider.overrideWith(
          () => FakeRecentViewModel(const RecentState()),
        ),
      ],
    );

    // The code to implement: the shell, Live open first.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PhoneShell()),
      ),
    );

    // The claim, on Live: the title, the two tabs in the navigation bar, Live
    // shown and History's view model not yet built.
    expect(find.widgetWithText(AppBar, 'Sensor node'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'Live'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'History'), findsOneWidget);
    expect(_shown(container), (live: true, history: false, built: false));

    // The code to implement: History, opened.
    await tester.tap(find.text('History'));
    await tester.pump();

    // The claim, on History: History shown in Live's place, its view model
    // built.
    expect(_shown(container), (live: false, history: true, built: true));
  });
}

/// Which tab is on screen, and whether History's view model has been built.
({bool live, bool history, bool built}) _shown(ProviderContainer container) => (
  live: find.byType(NodeScreen).evaluate().isNotEmpty,
  history: find.byType(RecentPanel).evaluate().isNotEmpty,
  built: container.exists(recentViewModelProvider),
);
