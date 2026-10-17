import 'dart:convert';
import 'dart:typed_data';

/// Labels for the Android application categories reported by the platform.
const Map<int, String> kAppCategoryLabels = <int, String>{
  -1: 'Other',
  0: 'Games',
  1: 'Audio',
  2: 'Video',
  3: 'Images',
  4: 'Social',
  5: 'News',
  6: 'Maps',
  7: 'Productivity',
  8: 'Accessibility',
};

/// Information about an application installed on the device.
class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.label,
    required this.category,
    this.icon,
  });

  final String packageName;
  final String label;

  /// Android `ApplicationInfo.category`, or -1 when undefined.
  final int category;

  /// PNG encoded icon bytes, or null when the icon could not be read.
  final Uint8List? icon;

  String get categoryLabel => kAppCategoryLabels[category] ?? 'Other';

  static AppInfo fromMap(Map<dynamic, dynamic> map) {
    final iconBase64 = map['icon'] as String?;
    return AppInfo(
      packageName: (map['packageName'] as String?) ?? '',
      label: (map['label'] as String?) ?? (map['packageName'] as String?) ?? 'Unknown',
      category: (map['category'] as num?)?.toInt() ?? -1,
      icon: iconBase64 == null ? null : base64Decode(iconBase64),
    );
  }
}
