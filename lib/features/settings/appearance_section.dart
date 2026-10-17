import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/settings_service.dart';
import '../../core/widgets/accent_picker.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_tiles.dart';
import '../../core/widgets/wallpaper_picker.dart';

/// Appearance settings: theme, accent colour, wallpaper and dock size.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
        SettingChoiceTile<String>(
          title: 'Theme',
          value: settings.themeMode,
          icon: Icons.brightness_6_outlined,
          options: const <String, String>{
            AeroThemeMode.system: 'System',
            AeroThemeMode.light: 'Light',
            AeroThemeMode.dark: 'Dark',
          },
          onChanged: notifier.setThemeMode,
        ),
        const SizedBox(height: 12),
        Text('Accent colour', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        AccentPicker(
          selectedId: settings.accentId,
          onSelected: notifier.setAccent,
        ),
        const SizedBox(height: 16),
        Text('Wallpaper', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        WallpaperPicker(
          selectedId: settings.wallpaperId,
          onSelected: notifier.setWallpaper,
        ),
        const SectionHeader(title: 'Dock', icon: Icons.dock_outlined),
        SettingSliderTile(
          title: 'Icon size',
          icon: Icons.format_size,
          value: settings.dockSize,
          min: 36,
          max: 72,
          divisions: 9,
          valueLabel: '${settings.dockSize.round()} px',
          onChanged: notifier.setDockSize,
        ),
        SettingSwitchTile(
          title: 'Auto-hide dock',
          subtitle: 'Show the dock when the pointer reaches the bottom edge',
          icon: Icons.visibility_off_outlined,
          value: settings.dockAutoHide,
          onChanged: notifier.setDockAutoHide,
        ),
      ],
    );
  }
}
