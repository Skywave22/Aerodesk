import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/aero_constants.dart';
import '../core/services/settings_service.dart';
import '../features/workspace/aerodesk_shell.dart';
import '../theme/accent_colors.dart';
import '../theme/aerodesk_theme.dart';

/// Root widget: applies the AeroDesk theme and hosts the shell.
class AeroDeskApp extends ConsumerWidget {
  const AeroDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final accent = AccentColorOption.byId(settings.accentId).seed;

    return MaterialApp(
      title: AeroConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAeroDeskTheme(brightness: Brightness.light, accent: accent),
      darkTheme: buildAeroDeskTheme(brightness: Brightness.dark, accent: accent),
      themeMode: switch (settings.themeMode) {
        AeroThemeMode.system => ThemeMode.system,
        AeroThemeMode.light => ThemeMode.light,
        AeroThemeMode.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: const AeroDeskShell(),
    );
  }
}
