import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/aero_constants.dart';
import '../../../core/services/settings_service.dart';
import '../../../theme/wallpapers.dart';
import 'desktop_item.dart';
import 'desktop_icon_item.dart';
import '../windows/aero_window.dart';
import '../windows/window_manager.dart';

/// Space kept between the icon grid and the edges of the desktop.
///
/// Without it the grid can spill icons past the right edge whenever the
/// available width is not an exact multiple of the cell width.
const double desktopGridMargin = 12;

/// The AeroDesk desktop: wallpaper, icons and open windows.
class DesktopView extends ConsumerStatefulWidget {
  const DesktopView({super.key, this.reservedBottom = 0});

  /// Height reserved at the bottom of the desktop (dock, navigation bar).
  ///
  /// Icons are never placed inside this strip, so the dock can no longer
  /// cover the last row of icons.
  final double reservedBottom;

  @override
  ConsumerState<DesktopView> createState() => _DesktopViewState();
}

/// Cell size of the desktop icon grid.
///
/// [compact] is used on short windows (landscape phones, split screen) where a
/// full size cell would only fit a single row of icons.
Size desktopIconCell(AeroSettings settings, {bool compact = false}) {
  if (!settings.showDesktopLabels) {
    return compact
        ? const Size(76, 76)
        : const Size(AeroConstants.desktopGrid, AeroConstants.desktopGrid);
  }
  return compact
      ? const Size(76, 96)
      : const Size(AeroConstants.desktopGrid, AeroConstants.desktopGrid + 22);
}

/// Area of the desktop that icons may occupy.
Rect desktopUsableArea(Size bounds, double reservedBottom, Size cell) {
  final width = (bounds.width - 2 * desktopGridMargin).clamp(cell.width, double.infinity);
  final height = (bounds.height - reservedBottom - desktopGridMargin)
      .clamp(cell.height, double.infinity);
  return Rect.fromLTWH(desktopGridMargin, desktopGridMargin, width, height);
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
        final compact = bounds.height < 460;
        final cell = desktopIconCell(settings, compact: compact);
        final usable = desktopUsableArea(bounds, widget.reservedBottom, cell);
        final columns = (usable.width / cell.width).floor().clamp(1, 12);
        final rows = (usable.height / cell.height).floor().clamp(1, 12);

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
                      _buildIcon(items[index], index, columns, rows, usable, workspace, cell),
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
    Rect usable,
    int workspace,
    Size cell,
  ) {
    final settings = ref.read(settingsProvider);
    final column = index % columns;
    final row = index ~/ columns;
    if (row >= rows) return const SizedBox.shrink();

    final grid = Offset(
      usable.left + column * cell.width,
      usable.top + row * cell.height,
    );
    final stored = _storedPosition(settings, workspace, item.id);
    // A position that no longer fits (saved on another screen size or before a
    // rotation) is re-flowed instead of being clamped into a corner.
    final position = stored != null && _fits(stored, usable, cell) ? stored : grid;

    return DesktopIconItem(
      key: ValueKey<String>('${item.kind.name}:${item.id}'),
      item: item,
      workspace: workspace,
      position: position,
      bounds: usable.size,
      cell: cell,
      boundsOrigin: usable.topLeft,
    );
  }

  /// Reads a persisted icon position for [itemId] on [workspace].
  Offset? _storedPosition(AeroSettings settings, int workspace, String itemId) {
    final stored = settings.iconPositions['workspace-$workspace:$itemId'];
    if (stored == null) return null;
    final parts = stored.split('|');
    if (parts.length != 2) return null;
    final x = double.tryParse(parts[0]);
    final y = double.tryParse(parts[1]);
    if (x == null || y == null) return null;
    return Offset(x, y);
  }

  /// True when an icon placed at [position] stays fully inside [usable].
  bool _fits(Offset position, Rect usable, Size cell) {
    return position.dx >= usable.left - 0.5 &&
        position.dy >= usable.top - 0.5 &&
        position.dx + cell.width <= usable.right + 0.5 &&
        position.dy + cell.height <= usable.bottom + 0.5;
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
