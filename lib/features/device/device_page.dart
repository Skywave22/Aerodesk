import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/apps_service.dart';
import '../../core/services/device_service.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/aero_empty_state.dart';
import '../../core/widgets/aero_panel.dart';

/// Device information gathered through public Android APIs.
final deviceSnapshotProvider = FutureProvider<DeviceSnapshot>((ref) {
  return const DeviceService().snapshot();
});

/// Hardware details reported by the platform channel.
final deviceExtrasProvider = FutureProvider<DeviceExtras>((ref) {
  return const AppsService().deviceExtras();
});

/// Device page: hardware information and app details.
class DevicePage extends ConsumerWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(deviceSnapshotProvider);
    final extras = ref.watch(deviceExtrasProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        snapshot.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InfoCard(
                title: 'Device',
                icon: Icons.phone_android_outlined,
                rows: <(String, String)>[
                  ('Manufacturer', data.manufacturer),
                  ('Model', data.model),
                  ('Device', data.device),
                  ('Board', data.board),
                  ('Hardware', data.hardware),
                  ('Product', data.product),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Software',
                icon: Icons.android_outlined,
                rows: <(String, String)>[
                  ('Android version', data.androidVersion),
                  ('SDK level', data.sdkInt == 0 ? 'Unknown' : '${data.sdkInt}'),
                  ('Security patch', data.securityPatch.isEmpty ? 'Not reported' : data.securityPatch),
                  ('CPU cores', data.cpuCores == 0 ? 'Unknown' : '${data.cpuCores}'),
                ],
              ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => AeroEmptyState(
            icon: Icons.error_outline,
            title: 'Device information unavailable',
            message: '$error',
            compact: true,
          ),
        ),
        const SizedBox(height: 12),
        extras.when(
          data: (data) => _InfoCard(
            title: 'Battery, storage and memory',
            icon: Icons.battery_charging_full_outlined,
            rows: <(String, String)>[
              ('Battery level', data.batteryLevel == null ? 'Unknown' : '${data.batteryLevel}%'),
              (
                'Charging',
                data.batteryCharging == null
                    ? 'Unknown'
                    : data.batteryCharging!
                        ? 'Yes'
                        : 'No'
              ),
              (
                'Battery temperature',
                data.batteryTemperatureC == null ? 'Unknown' : '${data.batteryTemperatureC} °C',
              ),
              ('Storage total', formatBytes(data.storageTotalBytes)),
              ('Storage available', formatBytes(data.storageAvailableBytes)),
              ('Memory total', formatBytes(data.memoryTotalBytes)),
              ('Memory available', formatBytes(data.memoryAvailableBytes)),
              ('Display refresh rate', data.refreshRate == null ? 'Unknown' : '${data.refreshRate} Hz'),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        _DisplayCard(),
        const SizedBox(height: 12),
        const _InfoCard(
          title: 'App',
          icon: Icons.apps_outlined,
          rows: <(String, String)>[
            ('Application id', 'com.aerodesk.aerodesk'),
            ('Licence', 'MIT'),
            ('Repository', 'github.com/Skywave22/Aerodesk'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Only public Android APIs are used. Values the platform does not report are shown as '
          '"Unknown" instead of being estimated.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _open('https://github.com/Skywave22/Aerodesk'),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open repository'),
          ),
        ),
      ],
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// A titled panel of label/value rows.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.rows});

  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              // Long card titles must ellipsise instead of overflowing on
              // narrow phone windows.
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 150,
                    child: Text(
                      row.$1,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text(row.$2, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Screen metrics reported by the Flutter view.
class _DisplayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final width = (size.width * ratio).round();
    final height = (size.height * ratio).round();
    return _InfoCard(
      title: 'Display',
      icon: Icons.screenshot_monitor_outlined,
      rows: <(String, String)>[
        ('Window size', '${size.width.round()} × ${size.height.round()} dp'),
        ('Resolution', '$width × $height px'),
        ('Density', '${ratio.toStringAsFixed(2)}x'),
        (
          'Form factor',
          size.width >= 840
              ? 'Tablet / desktop window'
              : size.width >= 600
                  ? 'Large phone / small tablet'
                  : 'Phone',
        ),
      ],
    );
  }
}
