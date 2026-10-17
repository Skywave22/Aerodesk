/// Global constants for AeroDesk.
class AeroConstants {
  const AeroConstants._();

  static const String appName = 'AeroDesk';
  static const String appTagline = 'A desktop workspace for Android';

  /// Method channel used for all native Android integrations.
  static const String channelApps = 'com.aerodesk/apps';

  /// SharedPreferences key holding the serialised [AeroDeskSettings].
  static const String prefsKeySettings = 'aerodesk.settings.v1';

  /// SharedPreferences key holding the notes module content.
  static const String prefsKeyNotes = 'aerodesk.notes.v1';

  /// Desktop icon grid cell size in logical pixels.
  static const double desktopGrid = 92;

  /// Window manager constraints.
  static const double minWindowWidth = 260;
  static const double minWindowHeight = 200;
  static const double windowTitleBarHeight = 40;

  /// Number of virtual workspaces.
  static const int workspaceCount = 4;

  /// Quick-access folders offered by AeroFiles.
  static const List<String> quickFolders = <String>[
    'Download',
    'Documents',
    'DCIM',
    'Pictures',
    'Screenshots',
    'Music',
    'Movies',
    'Android',
  ];

  /// Maximum number of apps kept in the "recently used" list.
  static const int maxRecentApps = 12;
}
