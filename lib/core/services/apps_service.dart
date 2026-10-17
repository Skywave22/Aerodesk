import 'package:flutter/services.dart';

import '../constants/aero_constants.dart';
import '../models/app_info.dart';

/// Static build and OS details reported by the native platform.
class DeviceProfile {
  const DeviceProfile({
    required this.manufacturer,
    required this.model,
    required this.device,
    required this.board,
    required this.hardware,
    required this.product,
    required this.androidVersion,
    required this.sdkInt,
    required this.securityPatch,
    required this.cpuCores,
  });

  final String manufacturer;
  final String model;
  final String device;
  final String board;
  final String hardware;
  final String product;
  final String androidVersion;
  final int sdkInt;
  final String securityPatch;
  final int cpuCores;

  static DeviceProfile fromMap(Map<dynamic, dynamic> map) {
    String text(Object? value) => (value as String?) ?? 'Unknown';
    return DeviceProfile(
      manufacturer: text(map['manufacturer']),
      model: text(map['model']),
      device: text(map['device']),
      board: text(map['board']),
      hardware: text(map['hardware']),
      product: text(map['product']),
      androidVersion: text(map['androidVersion']),
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
      securityPatch: (map['securityPatch'] as String?) ?? '',
      cpuCores: (map['cpuCores'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Version details of the app itself.
class AppVersion {
  const AppVersion({required this.version, required this.build});

  final String version;
  final String build;

  static AppVersion fromMap(Map<dynamic, dynamic> map) {
    return AppVersion(
      version: (map['version'] as String?) ?? 'Unknown',
      build: (map['build'] as String?) ?? '0',
    );
  }
}

/// A storage volume reported by the native platform.
class StorageVolume {
  const StorageVolume({
    required this.path,
    required this.label,
    required this.primary,
    required this.removable,
  });

  final String path;
  final String label;
  final bool primary;
  final bool removable;
}

/// Hardware details that are only available through native Android APIs.
class DeviceExtras {
  const DeviceExtras({
    this.batteryLevel,
    this.batteryCharging,
    this.batteryTemperatureC,
    this.storageTotalBytes,
    this.storageAvailableBytes,
    this.memoryTotalBytes,
    this.memoryAvailableBytes,
    this.refreshRate,
  });

  final int? batteryLevel;
  final bool? batteryCharging;
  final double? batteryTemperatureC;
  final int? storageTotalBytes;
  final int? storageAvailableBytes;
  final int? memoryTotalBytes;
  final int? memoryAvailableBytes;
  final double? refreshRate;
}

/// Thin wrapper around the native `com.aerodesk/apps` method channel.
///
/// Every call degrades gracefully (empty result / false) when the platform
/// side is unavailable, for example in unit tests.
class AppsService {
  const AppsService();

  static const MethodChannel _channel = MethodChannel(AeroConstants.channelApps);

  static const DeviceProfile _unknownProfile = DeviceProfile(
    manufacturer: 'Unknown',
    model: 'Unknown',
    device: 'Unknown',
    board: 'Unknown',
    hardware: 'Unknown',
    product: 'Unknown',
    androidVersion: 'Unknown',
    sdkInt: 0,
    securityPatch: '',
    cpuCores: 0,
  );

  Future<List<AppInfo>> installedApps() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('getInstalledApps');
      final apps = <AppInfo>[];
      for (final item in result ?? const <Object?>[]) {
        if (item is Map) {
          apps.add(AppInfo.fromMap(item));
        }
      }
      return apps;
    } on MissingPluginException {
      return const <AppInfo>[];
    } on PlatformException {
      return const <AppInfo>[];
    }
  }

  Future<bool> launchApp(String packageName) {
    return _boolCall('launchApp', <String, Object?>{'packageName': packageName});
  }

  Future<bool> openAppInfo(String packageName) {
    return _boolCall('openAppInfo', <String, Object?>{'packageName': packageName});
  }

  Future<bool> openFile(String path) {
    return _boolCall('openFile', <String, Object?>{'path': path});
  }

  Future<bool> hasAllFilesAccess() => _boolCall('hasAllFilesAccess');

  Future<bool> requestAllFilesAccess() => _boolCall('requestAllFilesAccess');

  Future<DeviceProfile> deviceProfile() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getDeviceProfile');
      return DeviceProfile.fromMap(result ?? const <Object?, Object?>{});
    } on MissingPluginException {
      return _unknownProfile;
    } on PlatformException {
      return _unknownProfile;
    }
  }

  Future<AppVersion> appVersion() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getAppVersion');
      return AppVersion.fromMap(result ?? const <Object?, Object?>{});
    } on MissingPluginException {
      return const AppVersion(version: 'Unknown', build: '0');
    } on PlatformException {
      return const AppVersion(version: 'Unknown', build: '0');
    }
  }

  Future<List<StorageVolume>> storageVolumes() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('getStorageVolumes');
      return (result ?? const <Object?>[])
          .whereType<Map>()
          .map(
            (map) => StorageVolume(
              path: (map['path'] as String?) ?? '',
              label: (map['label'] as String?) ?? 'Storage',
              primary: (map['primary'] as bool?) ?? false,
              removable: (map['removable'] as bool?) ?? false,
            ),
          )
          .toList();
    } on MissingPluginException {
      return const <StorageVolume>[];
    } on PlatformException {
      return const <StorageVolume>[];
    }
  }

  Future<DeviceExtras> deviceExtras() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getDeviceExtras');
      final map = result ?? const <Object?, Object?>{};
      return DeviceExtras(
        batteryLevel: (map['batteryLevel'] as num?)?.toInt(),
        batteryCharging: map['batteryCharging'] as bool?,
        batteryTemperatureC: (map['batteryTemperatureC'] as num?)?.toDouble(),
        storageTotalBytes: (map['storageTotalBytes'] as num?)?.toInt(),
        storageAvailableBytes: (map['storageAvailableBytes'] as num?)?.toInt(),
        memoryTotalBytes: (map['memoryTotalBytes'] as num?)?.toInt(),
        memoryAvailableBytes: (map['memoryAvailableBytes'] as num?)?.toInt(),
        refreshRate: (map['refreshRate'] as num?)?.toDouble(),
      );
    } on MissingPluginException {
      return const DeviceExtras();
    } on PlatformException {
      return const DeviceExtras();
    }
  }

  Future<bool> _boolCall(String method, [Map<String, Object?> arguments = const <String, Object?>{}]) async {
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
