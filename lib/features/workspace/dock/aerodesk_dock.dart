import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_info.dart';
import '../../../core/services/apps_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../theme/aerodesk_theme.dart';
import '../../modules/module_registry.dart';
import '../desktop/desktop_item.dart';
import 'app_launcher.dart';
import '../windows/window_manager.dart';

/// The AeroDesk dock: module shortcuts, recent apps and a desktop toggle.
class AeroDeskDock extends ConsumerStatefulWidget {
  const AeroDeskDock({super.key, this.bottomInset = 0});

  /// Extra space kept below the dock, e.g. for a bottom navigation bar.
  final double bottomInset;

  @override
  ConsumerState<AeroDeskDock> createState() => _AeroDeskDockState();
}

class _AeroDeskDockState extends ConsumerState<AeroDeskDock> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final autoHide = settings.dockAutoHide;
    final visible = !autoHide || _revealed;
    final iconSize = settings.dockSize - 20;

    final dock = Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: visible ? Offset.zero : const Offset(0, 1.4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: visible ? 1 : 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: 10 + widget.bottomInset),
            child: _DockSurface(iconSize: iconSize),
          ),
        ),
      ),
    );

    if (!autoHide) return dock;

    return Column(
      children: <Widget>[
        const Spacer(),
        MouseRegion(
          onEnter: (_) => setState(() => _revealed = true),
          onExit: (_) => setState(() => _revealed = false),
          child: const SizedBox(
            height: 8,
            width: double.infinity,
            child: ColoredBox(color: Colors.transparent),
          ),
        ),
        dock,
      ],
    );
  }
}

class _DockSurface extends ConsumerWidget {
  const _DockSurface({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workspace = ref.watch(activeWorkspaceProvider);
    final windows = ref.watch(windowsProvider);
    final recent = ref.watch(recentAppsProvider).take(6).toList();
    final apps = ref.watch(installedAppsProvider).valueOrNull ?? const [];

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DockButton(
              icon: Icons.grid_view_rounded,
              label: 'App launcher',
              size: iconSize,
              onPressed: () => _openLauncher(context),
            ),
            _DockDivider(),
            for (final module in kModules) ...<Widget>[
              _DockButton(
                icon: module.icon,
                label: module.title,
                size: iconSize,
                active: windows.any((window) => window.moduleId == module.id && !window.minimized),
                onPressed: () => ref.read(windowsProvider.notifier).open(module.id, workspace),
              ),
            ],
            if (recent.isNotEmpty) ...<Widget>[
              _DockDivider(),
              for (final packageName in recent) ...<Widget>[
                _DockAppButton(
                  app: appByPackage(apps, packageName),
                  size: iconSize,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _openLauncher(BuildContext context) => showAppLauncher(context);
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active ? theme.colorScheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: size * 0.72,
            color: active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DockAppButton extends ConsumerWidget {
  const _DockAppButton({required this.app, required this.size});

  final AppInfo? app;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final label = app?.label ?? app?.packageName ?? 'App';
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          final packageName = app?.packageName;
          if (packageName == null) return;
          rememberRecentApp(ref, packageName);
          const AppsService().launchApp(packageName);
        },
        child: Container(
          width: size + 12,
          height: size + 12,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: size * 0.82,
              height: size * 0.82,
              child: app?.icon == null
                  ? Icon(Icons.android_outlined, size: size * 0.6, color: theme.colorScheme.onSurfaceVariant)
                  : Image.memory(app!.icon!, gaplessPlayback: true),
            ),
          ),
        ),
      ),
    );
  }
}

/// Finds an installed application by package name.
AppInfo? appByPackage(List<AppInfo> apps, String packageName) {
  for (final app in apps) {
    if (app.packageName == packageName) return app;
  }
  return null;
}

class _DockDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 1,
      height: AeroDimens.radiusLg,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
    );
  }
}
