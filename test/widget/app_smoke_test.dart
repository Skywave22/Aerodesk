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

/// The navigation entry of a section, ignoring desktop icon labels.
Finder navEntry(String label) {
  return find.descendant(of: find.byType(NavigationBar), matching: find.text(label));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The native side is absent in widget tests: the channel is answered with
    // null, which the Dart services must tolerate.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(AeroConstants.channelApps), (call) async => null);
  });

  Future<SharedPreferences> preferences() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return SharedPreferences.getInstance();
  }

  testWidgets('the shell renders the desktop, dock and workspace switcher', (tester) async {
    final prefs = await preferences();

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

    expect(find.text('AeroDesk'), findsWidgets);
    // Desktop icons carry the same labels, so the navigation entries are
    // matched inside the navigation bar.
    for (final label in <String>['Workspace', 'Files', 'Settings', 'Device']) {
      expect(navEntry(label), findsOneWidget, reason: 'navigation entry "$label"');
    }
    expect(find.text('9:05 AM'), findsOneWidget);
  });

  testWidgets('opening a module window shows its title and closes again', (tester) async {
    final prefs = await preferences();
    await pumpApp(tester, prefs);

    await tester.tap(find.byTooltip('Calculator'));
    await settle(tester);

    // The window title and the dock tooltip both carry the module name.
    expect(find.text('Calculator'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Close'));
    await settle(tester);

    expect(find.text('Calculator'), findsOneWidget);
  });

  testWidgets('switching sections shows the settings page', (tester) async {
    final prefs = await preferences();
    await pumpApp(tester, prefs);

    await tester.tap(navEntry('Settings'));
    await settle(tester);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Accent colour'), findsOneWidget);
    expect(find.text('Wallpaper'), findsOneWidget);
  });

  testWidgets('the files page lists the storage roots', (tester) async {
    final prefs = await preferences();
    await pumpApp(tester, prefs);

    await tester.tap(navEntry('Files'));
    await settle(tester);

    // Once as a storage root chip and once as the root entry in the list.
    expect(find.text('App storage'), findsNWidgets(2));
    expect(find.text('Select a storage root'), findsOneWidget);
  });

  testWidgets('the device page reports unknown values without a platform', (tester) async {
    final prefs = await preferences();
    await pumpApp(tester, prefs);

    await tester.tap(navEntry('Device'));
    await settle(tester);

    expect(find.text('Manufacturer'), findsOneWidget);
    expect(find.text('Unknown'), findsWidgets);
  });
}

Future<void> pumpApp(WidgetTester tester, SharedPreferences prefs) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWith((ref) => Stream<DateTime>.value(DateTime(2026, 10, 17, 9, 5))),
        // path_provider needs a native platform in tests, so the storage roots
        // shown by AeroFiles are stubbed.
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
}
