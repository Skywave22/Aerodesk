import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_info.dart';
import '../../../core/services/apps_service.dart';
import '../../modules/module_registry.dart';

/// Where a desktop item came from.
enum DesktopItemKind { module, app }

/// One icon shown on the AeroDesk desktop.
class DesktopItem {
  const DesktopItem.module(this.definition)
      : kind = DesktopItemKind.module,
        app = null;

  const DesktopItem.app(this.app)
      : kind = DesktopItemKind.app,
        definition = null;

  final DesktopItemKind kind;

  /// Set when this item is a built-in module.
  final ModuleDefinition? definition;

  /// Set when this item is an installed application.
  final AppInfo? app;

  /// Stable id used for the persisted desktop position.
  String get id => switch (kind) {
        DesktopItemKind.module => definition!.id,
        DesktopItemKind.app => app!.packageName,
      };

  String get label => switch (kind) {
        DesktopItemKind.module => definition!.title,
        DesktopItemKind.app => app!.label,
      };

  IconData get icon => switch (kind) {
        DesktopItemKind.module => definition!.icon,
        DesktopItemKind.app => Icons.android_outlined,
      };

  Uint8List? get iconBytes => switch (kind) {
        DesktopItemKind.module => null,
        DesktopItemKind.app => app!.icon,
      };

  /// Rough "type" grouping used when icons are sorted by type.
  String get typeGroup => kind == DesktopItemKind.module ? 'AeroDesk' : 'Apps';

  bool get isApp => kind == DesktopItemKind.app;
}

/// Applications installed on the device.
final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) {
  return const AppsService().installedApps();
});

/// All desktop items: built-in modules first, then installed applications.
final desktopItemsProvider = Provider<List<DesktopItem>>((ref) {
  final items = <DesktopItem>[
    ...kModules.map<DesktopItem>(DesktopItem.module),
  ];
  final apps = ref.watch(installedAppsProvider).valueOrNull ?? const <AppInfo>[];
  items.addAll(apps.map<DesktopItem>(DesktopItem.app));
  return items;
});

/// Package names launched recently, most recent first.
final recentAppsProvider = StateProvider<List<String>>((ref) => const <String>[]);

/// Records an application launch so it can be offered in the dock.
void rememberRecentApp(WidgetRef ref, String packageName) {
  if (packageName.isEmpty) return;
  final current = ref.read(recentAppsProvider);
  final updated = <String>[
    packageName,
    ...current.where((entry) => entry != packageName),
  ].take(12).toList();
  ref.read(recentAppsProvider.notifier).state = updated;
}
