import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/settings_service.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_tiles.dart';

/// Behaviour settings: gestures, windows and icon sorting.
class BehaviourSection extends ConsumerWidget {
  const BehaviourSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Desktop', icon: Icons.desktop_windows_outlined),
        SettingSwitchTile(
          title: 'Show icon labels',
          subtitle: 'Hide labels to fit more icons on screen',
          icon: Icons.label_outline,
          value: settings.showDesktopLabels,
          onChanged: notifier.setShowDesktopLabels,
        ),
        SettingChoiceTile<IconSort>(
          title: 'Sort icons by',
          icon: Icons.sort,
          value: settings.iconSort,
          options: <IconSort, String>{
            for (final sort in IconSort.values) sort: sort.label,
          },
          onChanged: notifier.setIconSort,
        ),
        SettingSwitchTile(
          title: 'Double-tap to open',
          subtitle: 'When off, a single tap opens desktop icons',
          icon: Icons.touch_app_outlined,
          value: settings.doubleTapToOpen,
          onChanged: notifier.setDoubleTapToOpen,
        ),
        const SectionHeader(title: 'Windows', icon: Icons.web_asset_outlined),
        SettingSwitchTile(
          title: 'Snap layouts',
          subtitle: 'Offer half and quarter screen layouts',
          icon: Icons.crop_square_outlined,
          value: settings.windowSnapEnabled,
          onChanged: notifier.setWindowSnapEnabled,
        ),
        SettingSwitchTile(
          title: 'Window animations',
          subtitle: 'Disable to reduce motion on slower devices',
          icon: Icons.animation_outlined,
          value: settings.showWindowAnimations,
          onChanged: notifier.setShowWindowAnimations,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset settings?'),
                content: const Text('All AeroDesk settings return to their defaults.'),
                actions: <Widget>[
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reset')),
                ],
              ),
            );
            if (confirmed == true) notifier.resetToDefaults();
          },
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Reset all settings'),
        ),
      ],
    );
  }
}
