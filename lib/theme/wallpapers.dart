import 'package:flutter/material.dart';

/// A built-in desktop wallpaper rendered as a lightweight gradient.
///
/// Gradients are used instead of image assets so the app stays small and
/// renders instantly on low-end devices.
class WallpaperOption {
  const WallpaperOption({
    required this.id,
    required this.name,
    required this.colors,
    required this.begin,
    required this.end,
    required this.isDark,
  });

  final String id;
  final String name;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;
  final bool isDark;

  /// Colour used for icon labels drawn on top of this wallpaper.
  Color get iconLabelColor => isDark ? Colors.white : const Color(0xFF101828);

  /// Shadow that keeps labels readable on busy gradients.
  List<Shadow> get iconLabelShadows => isDark
      ? const <Shadow>[Shadow(blurRadius: 4, color: Colors.black87)]
      : const <Shadow>[Shadow(blurRadius: 4, color: Color(0x80FFFFFF))];

  /// Wallpapers offered in Settings -> Appearance and the quick panel.
  static const List<WallpaperOption> options = <WallpaperOption>[
    WallpaperOption(
      id: 'midnight',
      name: 'Midnight',
      colors: [Color(0xFF0B1220), Color(0xFF1E3A5F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      isDark: true,
    ),
    WallpaperOption(
      id: 'aurora',
      name: 'Aurora',
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      isDark: true,
    ),
    WallpaperOption(
      id: 'abyss',
      name: 'Abyss',
      colors: [Color(0xFF020617), Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      isDark: true,
    ),
    WallpaperOption(
      id: 'dusk',
      name: 'Dusk',
      colors: [Color(0xFF232526), Color(0xFF414345)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      isDark: true,
    ),
    WallpaperOption(
      id: 'ember',
      name: 'Ember',
      colors: [Color(0xFF2B1B12), Color(0xFF5C2E1B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      isDark: true,
    ),
    WallpaperOption(
      id: 'daylight',
      name: 'Daylight',
      colors: [Color(0xFFE8F0FE), Color(0xFFCFE0F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      isDark: false,
    ),
    WallpaperOption(
      id: 'sand',
      name: 'Sand',
      colors: [Color(0xFFFDF6EC), Color(0xFFEADFC8)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      isDark: false,
    ),
    WallpaperOption(
      id: 'mint',
      name: 'Mint',
      colors: [Color(0xFFE6F7F1), Color(0xFFC7E9DD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      isDark: false,
    ),
  ];

  static WallpaperOption byId(String id) {
    return options.firstWhere(
      (wallpaper) => wallpaper.id == id,
      orElse: () => options.first,
    );
  }
}
