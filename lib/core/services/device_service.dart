import 'apps_service.dart';

/// Snapshot of device and app information gathered from platform APIs.
class DeviceSnapshot {
  const DeviceSnapshot({
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
    required this.appVersion,
    required this.buildNumber,
    required this.packageName,
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
  final String appVersion;
  final String buildNumber;
  final String packageName;
}

/// Reads device information through supported Android APIs only.
///
/// All values come from the native `com.aerodesk/apps` channel; anything the
/// platform does not expose is reported as "Unknown" rather than guessed.
class DeviceService {
  const DeviceService();

  static const AppsService _apps = AppsService();

  Future<DeviceSnapshot> snapshot() async {
    final profile = await _apps.deviceProfile();
    final version = await _apps.appVersion();
    return DeviceSnapshot(
      manufacturer: profile.manufacturer,
      model: profile.model,
      device: profile.device,
      board: profile.board,
      hardware: profile.hardware,
      product: profile.product,
      androidVersion: profile.androidVersion,
      sdkInt: profile.sdkInt,
      securityPatch: profile.securityPatch,
      cpuCores: profile.cpuCores,
      appVersion: version.version,
      buildNumber: version.build,
      packageName: 'com.aerodesk.aerodesk',
    );
  }
}
