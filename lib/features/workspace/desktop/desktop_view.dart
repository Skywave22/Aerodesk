import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/aero_constants.dart';
import '../../../core/services/settings_service.dart';
import '../../../theme/wallpapers.dart';
import 'desktop_item.dart';
import 'desktop_icon_item.dart';
import '../windows/aero_window.dart';
import '../windows/window_manager.dart';

/// The AeroDesk desktop: wallpaper, icons and open windows.
class DesktopView extends ConsumerStatefulWidget {
  const DesktopView({super.key});

  @override
  ConsumerState<DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends ConsumerState<DesktopView> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final workspace = ref.watch(activeWorkspaceProvider);
    final windows = ref.watch(windowsProvider).where((window) => window.workspace == workspace);
    final wallpaper = WallpaperOption.byId(settings.wallpaperId);
    final items = ref.watch(desktopItemsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(constraints.maxWidth, constraints.maxHeight);
        final iconCell = settings.showDesktopLabels
            ? const Size(AeroConstants.desktopGrid, AeroConstants.desktopGrid + 22)
            : const Size(AeroConstants.desktopGrid, AeroConstants.desktopGrid);
        final columns = (bounds.width / iconCell.width).floor().clamp(1, 12);
        final rows = (bounds.height / iconCell.height).floor().clamp(1, 12);

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: wallpaper.colors,
                  begin: wallpaper.begin,
                  end: wallpaper.end,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTap: _showDesktopMenu,
                onTap: () => setState(() {}),
                child: Stack(
                  children: <Widget>[
                    for (var index = 0; index < items.length; index++)
                      _buildIcon(items[index], index, columns, rows, bounds, workspace),
                  ],
                ),
              ),
            ),
            for (final window in windows)
              AeroWindow(
                key: ValueKey<String>(window.id),
                window: window,
                bounds: Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                onActivate: () => ref.read(windowsProvider.notifier).focus(window.id),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIcon(
    DesktopItem item,
    int index,
    int columns,
    int rows,
    Size bounds,
    int workspace,
  ) {
    final settings = ref.read(settingsProvider);
    final iconCell = settings.showDesktopLabels
        ? const Size(AeroConstants.desktopGrid, AeroConstants.desktopGrid + 22)
        : const Size(AeroConstants.desktopGrid, AeroConstants.desktopGrid);
    final column = index % columns;
    final row = index ~/ columns;
    if (row >= rows) return const SizedBox.shrink();

    final stored = settings.iconPositions['workspace-$workspace:${item.id}'];
    Offset position;
    if (stored != null) {
      final parts = stored.split('|');
      if (parts.length == 2) {
        final x = double.tryParse(parts[0]);
        final y = double.tryParse(parts[1]);
        if (x != null && y != null) {
          position = Offset(x, y);
        } else {
          position = _gridPosition(column, row, iconCell);
        }
      } else {
        position = _gridPosition(column, row, iconCell);
      }
    } else {
      position = _gridPosition(column, row, iconCell);
    }

    return DesktopIconItem(
      key: ValueKey<String>('${item.kind.name}:${item.id}'),
      item: item,
      workspace: workspace,
      position: position,
      bounds: bounds,
    );
  }

  Offset _gridPosition(int column, int row, Size iconCell) {
    return Offset(12 + column * iconCell.width, 12 + row * iconCell.height);
  }

  Future<void> _showDesktopMenu() async {
    final notifier = ref.read(settingsProvider.notifier);
    final selection = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(24, 24, 24, 24),
      items: const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'next-wallpaper', child: Text('Change wallpaper')),
        PopupMenuItem<String>(value: 'sort', child: Text('Sort icons by name')),
        PopupMenuItem<String>(value: 'reset-icons', child: Text('Reset icon positions')),
        PopupMenuItem<String>(value: 'minimise', child: Text('Minimise all windows')),
      ],
    );
    if (selection == null) return;
    switch (selection) {
      case 'next-wallpaper':
        final current = WallpaperOption.byId(ref.read(settingsProvider).wallpaperId);
        final index = WallpaperOption.options.indexWhere((entry) => entry.id == current.id);
        final next = WallpaperOption.options[(index + 1) % WallpaperOption.options.length];
        notifier.setWallpaper(next.id);
      case 'sort':
        notifier.setIconSort(IconSort.name);
      case 'reset-icons':
        for (final workspace in List<int>.generate(AeroConstants.workspaceCount, (index) => index)) {
          for (final item in ref.read(desktopItemsProvider)) {
            notifier.clearIconPosition('workspace-$workspace', item.id);
          }
        }
      case 'minimise':
        ref.read(windowsProvider.notifier).minimizeAll(ref.read(activeWorkspaceProvider));
    }
  }
}
