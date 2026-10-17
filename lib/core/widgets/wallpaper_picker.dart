import 'package:flutter/material.dart';

import '../../theme/wallpapers.dart';

/// Grid picker for the built-in gradient wallpapers.
class WallpaperPicker extends StatelessWidget {
  const WallpaperPicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: WallpaperOption.options.map((wallpaper) {
        final selected = wallpaper.id == selectedId;
        return Semantics(
          label: '${wallpaper.name} wallpaper',
          selected: selected,
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(wallpaper.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 96,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: wallpaper.colors,
                  begin: wallpaper.begin,
                  end: wallpaper.end,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: selected
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: wallpaper.isDark ? Colors.white : const Color(0xFF101828),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          wallpaper.name,
                          style: TextStyle(
                            // Light wallpapers need dark labels: white text on a
                            // pale gradient was unreadable.
                            color: wallpaper.isDark ? Colors.white : const Color(0xFF101828),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            shadows: <Shadow>[
                              Shadow(
                                blurRadius: 4,
                                color: wallpaper.isDark
                                    ? Colors.black54
                                    : const Color(0x66FFFFFF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
