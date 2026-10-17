import 'package:aerodesk/app/app.dart';
import 'package:aerodesk/core/constants/aero_constants.dart';
import 'package:aerodesk/core/services/clock_service.dart';
import 'package:aerodesk/core/services/files_service.dart';
import 'package:aerodesk/core/services/settings_service.dart';
import 'package:aerodesk/features/files/files_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Waits until the widget tree is stable.
Future<void> settle(WidgetTester tester) {
  return tester.pumpAndSettle(const Duration(milliseconds: 400));
}

/// Rows whose children are wider than the row itself.
///
/// Flutter reports these as "A RenderFlex overflowed", which is how the
/// clipped icons and cut-off card titles on small windows showed up.
List<String> overflowingRows(WidgetTester tester) {
  final problems = <String>[];
  for (final element in find.byType(Row).evaluate()) {
    final render = element.renderObject as RenderBox;
    if (!render.hasSize) continue;
    var childWidth = 0.0;
    render.visitChildren((child) {
      if (child is RenderBox && child.hasSize) childWidth += child.size.width;
    });
    if (childWidth > render.size.width + 0.5) {
      problems.add('Row ${render.size} holds $childWidth of children');
    }
  }
  return problems;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The native side is absent in widget tests: the channel is answered with
    // null, which the Dart services must tolerate.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(AeroConstants.channelApps), (call) async => null);
  });

  // Phone portrait, phone landscape (the layout that used to clip icons) and
  // a large window where the navigation rail replaces the bottom bar.
  const sizes = <Size>[
    Size(360, 800),
    Size(645, 360),
    Size(800, 360),
    Size(1600, 900),
  ];

  for (final size in sizes) {
    testWidgets('sections, module windows and the launcher lay out cleanly at '
        '${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWith((ref) => Stream<DateTime>.value(DateTime(2026, 10, 17, 9, 5))),
            filesRootsProvider.overrideWith(
              (ref) async => const <StorageRoot>[
                StorageRoot(path: '/tmp/aerodesk', label: 'App storage', writable: true, primary: true),
              ],
            ),
          ],
          child: const AeroDeskApp(),
        ),
      );
      await settle(tester);

      final problems = <String>[];
      final nav = find.byType(NavigationBar).evaluate().isNotEmpty
          ? find.byType(NavigationBar)
          : find.byType(NavigationRail);

      for (final label in <String>['Files', 'Settings', 'Device']) {
        await tester.tap(find.descendant(of: nav, matching: find.text(label)));
        await settle(tester);
        final error = tester.takeException();
        if (error != null) problems.add('$label: $error');
        problems.addAll(overflowingRows(tester).map((row) => '$label: $row'));
      }

      // Module windows are opened from the desktop icons.
      await tester.tap(find.descendant(of: nav, matching: find.text('Workspace')));
      await settle(tester);
      for (final module in <String>['AeroFiles', 'Notes', 'Calculator', 'Clock']) {
        await tester.tap(find.text(module).first);
        await settle(tester);
        final error = tester.takeException();
        if (error != null) problems.add('$module window: $error');
        problems.addAll(overflowingRows(tester).map((row) => '$module: $row'));
      }

      await tester.tap(find.byTooltip('App launcher'));
      await settle(tester);
      final launcherError = tester.takeException();
      if (launcherError != null) problems.add('launcher: $launcherError');
      problems.addAll(overflowingRows(tester).map((row) => 'launcher: $row'));

      expect(problems, isEmpty);
    });
  }
}
