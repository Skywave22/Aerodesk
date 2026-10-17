import 'dart:convert';

import 'package:aerodesk/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final preferences = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(preferences)],
    );
  }

  setUp(() {});

  tearDown(() {
    container.dispose();
  });

  test('defaults are used when nothing is stored', () async {
    container = await containerWith(<String, Object>{});
    final settings = container.read(settingsProvider);

    expect(settings.themeMode, AeroThemeMode.system);
    expect(settings.accentId, 'sky');
    expect(settings.wallpaperId, 'midnight');
    expect(settings.dockSize, 48);
    expect(settings.iconSort, IconSort.name);
    expect(settings.showDesktopLabels, isTrue);
    expect(settings.doubleTapToOpen, isTrue);
    expect(settings.windowSnapEnabled, isTrue);
    expect(settings.iconPositions, isEmpty);
    expect(settings.pinnedPackages, isEmpty);
  });

  test('changes are persisted as a single JSON document', () async {
    container = await containerWith(<String, Object>{});
    final notifier = container.read(settingsProvider.notifier);

    notifier.setThemeMode(AeroThemeMode.dark);
    notifier.setAccent('violet');
    notifier.setWallpaper('aurora');
    notifier.setDockSize(64);
    notifier.setIconSort(IconSort.modified);
    notifier.setShowDesktopLabels(false);
    notifier.setDockAutoHide(true);
    notifier.togglePinnedApp('com.example.app');

    final stored = (await SharedPreferences.getInstance()).getString('aerodesk.settings.v1');
    expect(stored, isNotNull);

    final decoded = jsonDecode(stored!) as Map<String, dynamic>;
    expect(decoded['themeMode'], 'dark');
    expect(decoded['accentId'], 'violet');
    expect(decoded['wallpaperId'], 'aurora');
    expect(decoded['dockSize'], 64);
    expect(decoded['iconSort'], 'modified');
    expect(decoded['showDesktopLabels'], isFalse);
    expect(decoded['dockAutoHide'], isTrue);
    expect(decoded['pinnedPackages'], <String>['com.example.app']);

    final reloaded = await containerWith(<String, Object>{'aerodesk.settings.v1': stored});
    final settings = reloaded.read(settingsProvider);
    expect(settings.themeMode, 'dark');
    expect(settings.accentId, 'violet');
    expect(settings.dockSize, 64);
    expect(settings.iconSort, IconSort.modified);
    expect(settings.pinnedPackages, <String>['com.example.app']);
    reloaded.dispose();
  });

  test('icon positions are stored per workspace and item', () async {
    container = await containerWith(<String, Object>{});
    final notifier = container.read(settingsProvider.notifier);

    notifier.setIconPosition('workspace-0', 'notes', 120, 240);
    expect(container.read(settingsProvider).iconPositions['workspace-0:notes'], '120.0|240.0');

    notifier.clearIconPosition('workspace-0', 'notes');
    expect(container.read(settingsProvider).iconPositions.containsKey('workspace-0:notes'), isFalse);
  });

  test('dock size is clamped to a usable range', () async {
    container = await containerWith(<String, Object>{});
    final notifier = container.read(settingsProvider.notifier);

    notifier.setDockSize(4);
    expect(container.read(settingsProvider).dockSize, 36);

    notifier.setDockSize(500);
    expect(container.read(settingsProvider).dockSize, 72);
  });

  test('corrupted payloads fall back to defaults', () async {
    container = await containerWith(<String, Object>{'aerodesk.settings.v1': 'not json'});
    final settings = container.read(settingsProvider);
    expect(settings.themeMode, AeroThemeMode.system);
    expect(settings.dockSize, 48);
  });

  test('reset restores every default', () async {
    container = await containerWith(<String, Object>{});
    final notifier = container.read(settingsProvider.notifier);

    notifier.setThemeMode(AeroThemeMode.light);
    notifier.setAccent('rose');
    notifier.resetToDefaults();

    final settings = container.read(settingsProvider);
    expect(settings.themeMode, AeroThemeMode.system);
    expect(settings.accentId, 'sky');
  });
}
