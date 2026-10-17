import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/aero_constants.dart';
import '../../../theme/aerodesk_theme.dart';
import '../../modules/module_builders.dart';
import '../../modules/module_registry.dart';
import 'snap_layout_picker.dart';
import 'window_manager.dart';
import 'window_state.dart';

/// A single desktop window: title bar, content and a resize handle.
class AeroWindow extends ConsumerStatefulWidget {
  const AeroWindow({
    super.key,
    required this.window,
    required this.bounds,
    this.onActivate,
  });

  final AeroWindowModel window;

  /// Area of the desktop the window may occupy.
  final Rect bounds;

  /// Called when the window takes focus.
  final VoidCallback? onActivate;

  @override
  ConsumerState<AeroWindow> createState() => _AeroWindowState();
}

class _AeroWindowState extends ConsumerState<AeroWindow> {
  bool _hoveringTitleBar = false;
  bool _hoveringResize = false;
  bool _showSnapPanel = false;

  AeroWindowModel get window => widget.window;

  Rect get bounds => widget.bounds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final module = moduleById(window.moduleId);
    final focused = ref.watch(focusedWindowProvider) == window.id;
    final maximized = window.snap == WindowSnap.maximize;

    if (window.minimized) return const SizedBox.shrink();

    final borderRadius = maximized
        ? BorderRadius.zero
        : BorderRadius.circular(AeroDimens.radiusMd);

    return Positioned(
      left: window.offset.dx,
      top: window.offset.dy,
      width: window.size.width,
      height: window.size.height,
      child: MouseRegion(
        cursor: _hoveringTitleBar ? SystemMouseCursors.move : SystemMouseCursors.basic,
        child: Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) widget.onActivate?.call();
          },
          child: Stack(
            children: <Widget>[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: focused ? 1 : 0.97,
                child: Material(
                  elevation: focused ? 10 : 4,
                  shadowColor: Colors.black54,
                  borderRadius: borderRadius,
                  clipBehavior: Clip.antiAlias,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: focused
                            ? theme.colorScheme.primary.withValues(alpha: 0.55)
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        _buildTitleBar(context, module, maximized),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: maximized
                                ? BorderRadius.zero
                                : const BorderRadius.vertical(bottom: Radius.circular(AeroDimens.radiusMd)),
                            child: buildModule(context, window.moduleId),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!maximized) _buildResizeHandle(theme),
              if (_showSnapPanel)
                Positioned(
                  right: 0,
                  top: AeroConstants.windowTitleBarHeight + 4,
                  child: SnapLayoutPicker(
                    onSelected: (snap) {
                      setState(() => _showSnapPanel = false);
                      ref.read(windowsProvider.notifier).snap(window.id, snap, bounds);
                    },
                    onDismiss: () => setState(() => _showSnapPanel = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, ModuleDefinition module, bool maximized) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveringTitleBar = true),
      onExit: (_) => setState(() => _hoveringTitleBar = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(windowsProvider.notifier).focus(window.id),
        onDoubleTap: () => ref.read(windowsProvider.notifier).toggleMaximize(window.id, bounds),
        onPanStart: (_) => ref.read(windowsProvider.notifier).focus(window.id),
        onPanUpdate: (details) {
          if (window.snap != WindowSnap.none) return;
          ref.read(windowsProvider.notifier).move(window.id, details.delta, bounds);
        },
        onSecondaryTap: _showWindowMenu,
        child: Container(
          height: AeroConstants.windowTitleBarHeight,
          padding: const EdgeInsets.only(left: 12, right: 6),
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
          child: Row(
            children: <Widget>[
              Icon(module.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  module.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _WindowButton(
                icon: Icons.remove,
                tooltip: 'Minimise',
                onPressed: () => ref.read(windowsProvider.notifier).toggleMinimize(window.id),
              ),
              _WindowButton(
                icon: maximized ? Icons.filter_none : Icons.crop_square,
                tooltip: 'Snap layouts',
                onPressed: () => setState(() => _showSnapPanel = !_showSnapPanel),
              ),
              _WindowButton(
                icon: Icons.close,
                tooltip: 'Close',
                onPressed: () => ref.read(windowsProvider.notifier).close(window.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle(ThemeData theme) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: MouseRegion(
        cursor: _hoveringResize ? SystemMouseCursors.resizeUpLeftDownRight : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hoveringResize = true),
        onExit: (_) => setState(() => _hoveringResize = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            if (window.snap != WindowSnap.none) return;
            final delta = details.delta;
            ref.read(windowsProvider.notifier).resize(
                  window.id,
                  Size(delta.dx, delta.dy),
                  bounds,
                );
          },
          child: SizedBox(
            width: 18,
            height: 18,
            child: CustomPaint(
              painter: _ResizeGripPainter(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWindowMenu() async {
    final notifier = ref.read(windowsProvider.notifier);
    final theme = Theme.of(context);
    final selection = await showMenu<_WindowMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(window.offset.dx, window.offset.dy + 40, 8, 0),
      items: <PopupMenuEntry<_WindowMenuAction>>[
        PopupMenuItem<_WindowMenuAction>(
          value: _WindowMenuAction.snapLeft,
          child: Text('Snap ${WindowSnap.left.label.toLowerCase()}'),
        ),
        PopupMenuItem<_WindowMenuAction>(
          value: _WindowMenuAction.snapRight,
          child: Text('Snap ${WindowSnap.right.label.toLowerCase()}'),
        ),
        const PopupMenuItem<_WindowMenuAction>(
          value: _WindowMenuAction.maximize,
          child: Text('Maximise'),
        ),
        const PopupMenuItem<_WindowMenuAction>(
          value: _WindowMenuAction.restore,
          child: Text('Restore'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_WindowMenuAction>(
          value: _WindowMenuAction.close,
          child: Text('Close window', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ],
    );
    if (selection == null) return;
    switch (selection) {
      case _WindowMenuAction.snapLeft:
        notifier.snap(window.id, WindowSnap.left, bounds);
      case _WindowMenuAction.snapRight:
        notifier.snap(window.id, WindowSnap.right, bounds);
      case _WindowMenuAction.maximize:
        notifier.snap(window.id, WindowSnap.maximize, bounds);
      case _WindowMenuAction.restore:
        notifier.snap(window.id, WindowSnap.none, bounds);
      case _WindowMenuAction.close:
        notifier.close(window.id);
    }
  }
}

enum _WindowMenuAction { snapLeft, snapRight, maximize, restore, close }

/// A flat window control button.
class _WindowButton extends StatelessWidget {
  const _WindowButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 16,
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _ResizeGripPainter extends CustomPainter {
  const _ResizeGripPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 3; i++) {
      final offset = size.width - i * 4.5;
      canvas.drawLine(Offset(offset, size.height - 2), Offset(size.width - 2, offset), paint);
    }
  }

  @override
  bool shouldRepaint(_ResizeGripPainter oldDelegate) => oldDelegate.color != color;
}
