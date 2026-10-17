import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/apps_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../theme/aerodesk_theme.dart';
import '../../../theme/wallpapers.dart';
import 'desktop_item.dart';
import '../windows/window_manager.dart';

/// A draggable desktop icon.
///
/// Dragging keeps the position in local state and only writes to settings when
/// the gesture ends: writing on every pointer move would serialise settings
/// and hit the disk dozens of times per second, which made drags stutter.
class DesktopIconItem extends ConsumerStatefulWidget {
  const DesktopIconItem({
    super.key,
    required this.item,
    required this.workspace,
    required this.position,
    required this.bounds,
    required this.cell,
    this.boundsOrigin = Offset.zero,
  });

  final DesktopItem item;

  /// Index of the workspace the icon lives on.
  final int workspace;

  /// Position of the icon in desktop coordinates.
  final Offset position;

  /// Size of the area icons may occupy, used to keep them on screen.
  final Size bounds;

  /// Cell size used by the grid, used for clamping and the context menu.
  final Size cell;

  /// Top-left corner of [bounds] in desktop coordinates.
  final Offset boundsOrigin;

  @override
  ConsumerState<DesktopIconItem> createState() => _DesktopIconItemState();
}

class _DesktopIconItemState extends ConsumerState<DesktopIconItem> {
  bool _selected = false;
  bool _dragging = false;
  Offset? _dragOffset;

  Size get _iconCell => widget.cell;

  /// Clamps [offset] so the icon stays inside the desktop area.
  Offset _clamp(Offset offset) {
    final size = _iconCell;
    final maxX = (widget.bounds.width - size.width).clamp(0.0, double.infinity);
    final maxY = (widget.bounds.height - size.height).clamp(0.0, double.infinity);
    return Offset(
      offset.dx.clamp(0.0, maxX),
      offset.dy.clamp(0.0, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final size = widget.cell;
    final theme = Theme.of(context);
    final wallpaper = WallpaperOption.byId(settings.wallpaperId);

    final base = _clamp(widget.position - widget.boundsOrigin);
    final offset = _dragOffset ?? base;

    return Positioned(
      left: widget.boundsOrigin.dx + offset.dx,
      top: widget.boundsOrigin.dy + offset.dy,
      width: size.width,
      height: size.height,
      child: RepaintBoundary(
        child: MouseRegion(
          cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _selected = true);
              if (!settings.doubleTapToOpen) _activate();
            },
            onDoubleTap: _activate,
            onLongPress: _showItemMenu,
            onSecondaryTap: _showItemMenu,
            onPanStart: (_) => setState(() {
              _dragging = true;
              _dragOffset = base;
            }),
            onPanUpdate: (details) => setState(() {
              _dragOffset = _clamp((_dragOffset ?? base) + details.delta);
            }),
            onPanEnd: (_) => _commitDrag(),
            onPanCancel: _commitDrag,
            child: Semantics(
              label: widget.item.label,
              button: true,
              selected: _selected,
              child: AnimatedContainer(
                duration: _dragging ? Duration.zero : const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AeroDimens.radiusSm),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildIcon(theme),
                    if (settings.showDesktopLabels) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        widget.item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: wallpaper.iconLabelColor,
                          shadows: wallpaper.iconLabelShadows,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final bytes = widget.item.iconBytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, width: 44, height: 44, gaplessPlayback: true),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primary.withValues(alpha: 0.16),
      ),
      child: Icon(widget.item.icon, size: 24, color: theme.colorScheme.primary),
    );
  }

  /// Writes the final drag position once, then leaves drag mode.
  void _commitDrag() {
    final offset = _dragOffset;
    setState(() {
      _dragging = false;
      _dragOffset = null;
    });
    if (offset == null) return;
    final absolute = offset + widget.boundsOrigin;
    ref.read(settingsProvider.notifier).setIconPosition(
          'workspace-${widget.workspace}',
          widget.item.id,
          absolute.dx,
          absolute.dy,
        );
  }

  void _activate() {
    setState(() => _selected = true);
    final notifier = ref.read(windowsProvider.notifier);
    if (widget.item.isApp) {
      const AppsService().launchApp(widget.item.id).then((ok) {
        if (!ok) _showLaunchFailed();
      });
      rememberRecentApp(ref, widget.item.id);
      return;
    }
    notifier.open(widget.item.id, widget.workspace);
  }

  void _showLaunchFailed() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open ${widget.item.label}')),
    );
  }

  Future<void> _showItemMenu() async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      renderBox.localToGlobal(Offset.zero) & _iconCell,
      overlay.semanticBounds,
    );
    final selection = await showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'open',
          child: Text(widget.item.isApp ? 'Open app' : 'Open'),
        ),
        if (widget.item.isApp) ...<PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'info',
            child: Text('App info'),
          ),
          PopupMenuItem<String>(
            value: 'pin',
            child: Text(ref.read(settingsProvider.notifier).isPinned(widget.item.id)
                ? 'Unpin from launcher'
                : 'Pin to launcher'),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'reset',
          child: Text('Reset position'),
        ),
      ],
    );
    if (selection == null) return;
    switch (selection) {
      case 'open':
        _activate();
      case 'info':
        const AppsService().openAppInfo(widget.item.id);
      case 'pin':
        ref.read(settingsProvider.notifier).togglePinnedApp(widget.item.id);
      case 'reset':
        ref.read(settingsProvider.notifier).clearIconPosition(
              'workspace-${widget.workspace}',
              widget.item.id,
            );
    }
    if (!mounted) return;
    setState(() => _selected = false);
  }
}
