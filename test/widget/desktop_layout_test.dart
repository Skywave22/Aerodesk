import 'dart:convert';

import 'package:aerodesk/app/app.dart';
import 'package:aerodesk/core/constants/aero_constants.dart';
import 'package:aerodesk/core/services/clock_service.dart';
import 'package:aerodesk/core/services/files_service.dart';
import 'package:aerodesk/core/services/settings_service.dart';
import 'package:aerodesk/features/files/files_page.dart';
import 'package:aerodesk/theme/wallpapers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Waits until the widget tree is stable.
Future<void> settle(WidgetTester tester) {
  return tester.pumpAndSettle(const Duration(milliseconds: 400));
}

/// Pumps the app with an optional preference seed.
Future<SharedPreferences> pumpApp(WidgetTester tester, [Map<String, Object> seed = const <String, Object>{}]) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        // The clock stream is replaced with a single value so the widget test
        // does not depend on periodic timers.
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
  return prefs;
}

/// All desktop icon rectangles.
List<Rect> iconRects(WidgetTester tester) {
  final rects = <Rect>[];
  for (final positioned in tester.widgetList<Positioned>(find.byType(Positioned))) {
    if (positioned.left == null || positioned.top == null) continue;
    final size = Size(positioned.width ?? 0, positioned.height ?? 0);
    if (size.width < 40 || size.height < 40) continue;
    rects.add(Offset(positioned.left!, positioned.top!) & size);
  }
  return rects;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The native side is absent in widget tests: the channel is answered with
    // null, which the Dart services must tolerate.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(AeroConstants.channelApps), (call) async => null);
  });

  group('desktop grid layout', () {
    // Window sizes that previously produced clipped icons or a dock that
    // covered the last row: the 645x360 landscape size used to spill the last
    // column off the right edge.
    const sizes = <Size>[
      Size(360, 800),
      Size(412, 915),
      Size(645, 360),
      Size(800, 360),
      Size(1600, 900),
    ];

    for (final size in sizes) {
      testWidgets('icons stay inside the desktop and clear of the dock at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpApp(tester);

        final rects = iconRects(tester);
        expect(rects, isNotEmpty);
        for (final rect in rects) {
          expect(rect.right, lessThanOrEqualTo(size.width),
              reason: 'icon at $rect leaves the right edge');
          expect(rect.bottom, lessThanOrEqualTo(size.height),
              reason: 'icon at $rect leaves the bottom edge');
          // The dock floats at the bottom: icons must stop above it.
          expect(rect.bottom, lessThanOrEqualTo(size.height - 30),
              reason: 'icon at $rect is hidden behind the dock');
        }
      });
    }

    testWidgets('every module icon is reachable on a portrait phone', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester);

      for (final module in <String>['AeroFiles', 'Notes', 'Calculator', 'Clock', 'Settings', 'Device']) {
        expect(find.text(module), findsWidgets, reason: '$module icon is missing from the desktop');
      }
    });

    testWidgets('stale icon positions saved on another screen size are re-flowed', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester, <String, Object>{
        AeroConstants.prefsKeySettings: jsonEncode(<String, Object>{
          'wallpaperId': 'midnight',
          // A position that only fits a much wider desktop.
          'iconPositions': <String, Object>{'workspace-0:files': '900|700'},
        }),
      });

      for (final rect in iconRects(tester)) {
        expect(rect.right, lessThanOrEqualTo(360));
        expect(rect.bottom, lessThanOrEqualTo(800 - 30));
      }
    });
  });

  group('wallpaper contrast', () {
    testWidgets('light wallpapers use dark icon labels', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester, <String, Object>{
        AeroConstants.prefsKeySettings: jsonEncode(<String, Object>{'wallpaperId': 'daylight'}),
      });

      final label = tester.widget<Text>(find.text('AeroFiles').first);
      expect(label.style?.color, isNotNull);
      // Dark text on a pale gradient: white labels used to be unreadable.
      expect(label.style!.color!.computeLuminance(), lessThan(0.5));
    });

    test('dark wallpapers keep light labels', () {
      final wallpaper = WallpaperOption.byId('midnight');
      expect(wallpaper.iconLabelColor.computeLuminance(), greaterThan(0.5));
    });
  });

  group('app launcher', () {
    testWidgets('the launcher panel fits inside a short window', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester);

      await tester.tap(find.byTooltip('App launcher'));
      await settle(tester);

      final panel = tester.getRect(find.byType(Material).last);
      expect(panel.left, greaterThanOrEqualTo(0));
      expect(panel.top, greaterThanOrEqualTo(0));
      expect(panel.right, lessThanOrEqualTo(800));
      expect(panel.bottom, lessThanOrEqualTo(360));
    });
  });
}
