import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apps_service.dart';
import 'files_service.dart';

/// SharedPreferences instance used by the settings notifier.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// How the desktop icons are arranged.
enum IconSort { name, type, size, modified }

/// Extension of [IconSort] with the labels shown in Settings.
extension IconSortLabel on IconSort {
  String get label {
    switch (this) {
      case IconSort.name:
        return 'Name';
      case IconSort.type:
        return 'Type';
      case IconSort.size:
        return 'Size';
      case IconSort.modified:
        return 'Date modified';
    }
  }
}

/// Values accepted by [AeroSettings.themeMode].
class AeroThemeMode {
  const AeroThemeMode._();

  static const String system = 'system';
  static const String light = 'light';
  static const String dark = 'dark';
}

/// All user-configurable AeroDesk settings.
///
/// The whole object is stored as a single JSON string so the schema can evolve
/// without migrating many individual keys.
class AeroSettings {
  const AeroSettings({
    required this.themeMode,
    required this.accentId,
    required this.wallpaperId,
    required this.dockSize,
    required this.showDesktopLabels,
    required this.iconSort,
    required this.doubleTapToOpen,
    required this.windowSnapEnabled,
    required this.dockAutoHide,
    required this.showWindowAnimations,
    required this.firstLaunch,
    required this.pinnedPackages,
    required this.iconPositions,
  });

  factory AeroSettings.defaults() {
    return const AeroSettings(
      themeMode: 'system',
      accentId: 'sky',
      wallpaperId: 'midnight',
      dockSize: 48,
      showDesktopLabels: true,
      iconSort: IconSort.name,
      doubleTapToOpen: true,
      windowSnapEnabled: true,
      dockAutoHide: false,
      showWindowAnimations: true,
      firstLaunch: true,
      pinnedPackages: <String>[],
      iconPositions: <String, String>{},
    );
  }

  /// One of `system`, `light` or `dark`.
  final String themeMode;
  final String accentId;
  final String wallpaperId;
  final double dockSize;
  final bool showDesktopLabels;
  final IconSort iconSort;
  final bool doubleTapToOpen;
  final bool windowSnapEnabled;
  final bool dockAutoHide;
  final bool showWindowAnimations;
  final bool firstLaunch;

  /// Package names pinned to the app launcher.
  final List<String> pinnedPackages;

  /// Maps `"<workspace>:<itemId>"` to an `"x|y"` desktop position.
  final Map<String, String> iconPositions;

  AeroSettings copyWith({
    String? themeMode,
    String? accentId,
    String? wallpaperId,
    double? dockSize,
    bool? showDesktopLabels,
    IconSort? iconSort,
    bool? doubleTapToOpen,
    bool? windowSnapEnabled,
    bool? dockAutoHide,
    bool? showWindowAnimations,
    bool? firstLaunch,
    List<String>? pinnedPackages,
    Map<String, String>? iconPositions,
  }) {
    return AeroSettings(
      themeMode: themeMode ?? this.themeMode,
      accentId: accentId ?? this.accentId,
      wallpaperId: wallpaperId ?? this.wallpaperId,
      dockSize: dockSize ?? this.dockSize,
      showDesktopLabels: showDesktopLabels ?? this.showDesktopLabels,
      iconSort: iconSort ?? this.iconSort,
      doubleTapToOpen: doubleTapToOpen ?? this.doubleTapToOpen,
      windowSnapEnabled: windowSnapEnabled ?? this.windowSnapEnabled,
      dockAutoHide: dockAutoHide ?? this.dockAutoHide,
      showWindowAnimations: showWindowAnimations ?? this.showWindowAnimations,
      firstLaunch: firstLaunch ?? this.firstLaunch,
      pinnedPackages: pinnedPackages ?? this.pinnedPackages,
      iconPositions: iconPositions ?? this.iconPositions,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themeMode': themeMode,
      'accentId': accentId,
      'wallpaperId': wallpaperId,
      'dockSize': dockSize,
      'showDesktopLabels': showDesktopLabels,
      'iconSort': iconSort.name,
      'doubleTapToOpen': doubleTapToOpen,
      'windowSnapEnabled': windowSnapEnabled,
      'dockAutoHide': dockAutoHide,
      'showWindowAnimations': showWindowAnimations,
      'firstLaunch': firstLaunch,
      'pinnedPackages': pinnedPackages,
      'iconPositions': iconPositions,
    };
  }

  static AeroSettings fromJson(Map<String, dynamic> json) {
    final defaults = AeroSettings.defaults();
    return AeroSettings(
      themeMode: (json['themeMode'] as String?) ?? defaults.themeMode,
      accentId: (json['accentId'] as String?) ?? defaults.accentId,
      wallpaperId: (json['wallpaperId'] as String?) ?? defaults.wallpaperId,
      dockSize: (json['dockSize'] as num?)?.toDouble() ?? defaults.dockSize,
      showDesktopLabels: (json['showDesktopLabels'] as bool?) ?? defaults.showDesktopLabels,
      iconSort: IconSort.values.firstWhere(
        (value) => value.name == json['iconSort'],
        orElse: () => defaults.iconSort,
      ),
      doubleTapToOpen: (json['doubleTapToOpen'] as bool?) ?? defaults.doubleTapToOpen,
      windowSnapEnabled: (json['windowSnapEnabled'] as bool?) ?? defaults.windowSnapEnabled,
      dockAutoHide: (json['dockAutoHide'] as bool?) ?? defaults.dockAutoHide,
      showWindowAnimations: (json['showWindowAnimations'] as bool?) ?? defaults.showWindowAnimations,
      firstLaunch: (json['firstLaunch'] as bool?) ?? defaults.firstLaunch,
      pinnedPackages: _decodeStringList(json['pinnedPackages']),
      iconPositions: _decodeIconPositions(json['iconPositions']),
    );
  }

  static List<String> _decodeStringList(Object? raw) {
    if (raw is List) return raw.map((entry) => entry.toString()).toList();
    return const <String>[];
  }

  static Map<String, String> _decodeIconPositions(Object? raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    return <String, String>{};
  }
}

/// Persists settings in SharedPreferences.
class SettingsNotifier extends Notifier<AeroSettings> {
  static const String _settingsKey = 'aerodesk.settings.v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AeroSettings build() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return AeroSettings.defaults();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return AeroSettings.fromJson(decoded);
      if (decoded is Map) return AeroSettings.fromJson(decoded.cast<String, dynamic>());
    } on FormatException {
      // Corrupted payload: fall back to defaults instead of crashing.
    }
    return AeroSettings.defaults();
  }

  void _persist() {
    _prefs.setString(_settingsKey, jsonEncode(state.toJson()));
  }

  void setThemeMode(String mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setAccent(String accentId) {
    state = state.copyWith(accentId: accentId);
    _persist();
  }

  void setWallpaper(String wallpaperId) {
    state = state.copyWith(wallpaperId: wallpaperId);
    _persist();
  }

  void setDockSize(double size) {
    final clamped = size.clamp(36.0, 72.0);
    state = state.copyWith(dockSize: clamped);
    _persist();
  }

  void setShowDesktopLabels(bool value) {
    state = state.copyWith(showDesktopLabels: value);
    _persist();
  }

  void setIconSort(IconSort sort) {
    state = state.copyWith(iconSort: sort);
    _persist();
  }

  void setDoubleTapToOpen(bool value) {
    state = state.copyWith(doubleTapToOpen: value);
    _persist();
  }

  void setWindowSnapEnabled(bool value) {
    state = state.copyWith(windowSnapEnabled: value);
    _persist();
  }

  void setDockAutoHide(bool value) {
    state = state.copyWith(dockAutoHide: value);
    _persist();
  }

  void setShowWindowAnimations(bool value) {
    state = state.copyWith(showWindowAnimations: value);
    _persist();
  }

  void setFirstLaunch(bool value) {
    state = state.copyWith(firstLaunch: value);
    _persist();
  }

  /// Stores the position of one desktop icon.
  void setIconPosition(String workspace, String itemId, double x, double y) {
    final key = '$workspace:$itemId';
    final updated = Map<String, String>.from(state.iconPositions)..[key] = '$x|$y';
    state = state.copyWith(iconPositions: updated);
    _persist();
  }

  /// Removes the stored position of one desktop icon.
  void clearIconPosition(String workspace, String itemId) {
    final key = '$workspace:$itemId';
    if (!state.iconPositions.containsKey(key)) return;
    final updated = Map<String, String>.from(state.iconPositions)..remove(key);
    state = state.copyWith(iconPositions: updated);
    _persist();
  }

  /// Pins or unpins an application in the launcher.
  void togglePinnedApp(String packageName) {
    final pinned = List<String>.from(state.pinnedPackages);
    if (!pinned.remove(packageName)) pinned.add(packageName);
    state = state.copyWith(pinnedPackages: pinned);
    _persist();
  }

  /// True when [packageName] is pinned in the launcher.
  bool isPinned(String packageName) => state.pinnedPackages.contains(packageName);

  void resetToDefaults() {
    state = AeroSettings.defaults();
    _persist();
  }
}

/// The app-wide settings state.
final settingsProvider = NotifierProvider<SettingsNotifier, AeroSettings>(SettingsNotifier.new);

/// Launches an installed application through the native channel.
final launchAppProvider = FutureProvider.family<bool, String>((ref, packageName) {
  return const AppsService().launchApp(packageName);
});

/// Opens the system settings page of an installed application.
final openAppInfoProvider = FutureProvider.family<bool, String>((ref, packageName) {
  return const AppsService().openAppInfo(packageName);
});

/// Checks whether the app can read and write shared storage.
final allFilesAccessProvider = FutureProvider<bool>((ref) {
  return const FilesService().hasAllFilesAccess();
});
