import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/apps_service.dart';
import '../../../core/services/settings_service.dart';
import '../../modules/module_registry.dart';
import '../desktop/desktop_item.dart';
import '../windows/window_manager.dart';

/// Opens the app launcher overlay.
void showAppLauncher(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'App launcher',
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) => const AppLauncherOverlay(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      );
    },
  );
}

/// Full-screen launcher listing modules, pinned apps and installed apps.
class AppLauncherOverlay extends ConsumerStatefulWidget {
  const AppLauncherOverlay({super.key});

  @override
  ConsumerState<AppLauncherOverlay> createState() => _AppLauncherOverlayState();
}

class _AppLauncherOverlayState extends ConsumerState<AppLauncherOverlay> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ref.watch(desktopItemsProvider);
    final pinned = ref.watch(settingsProvider).pinnedPackages;
    final query = _query.trim().toLowerCase();

    List<DesktopItem> matching(DesktopItem item) => item.label.toLowerCase().contains(query)
        ? <DesktopItem>[item]
        : const <DesktopItem>[];

    final pinnedItems = items
        .where((item) => item.isApp && pinned.contains(item.id) && matching(item).isNotEmpty)
        .toList();
    final moduleItems = kModules
        .where((module) => module.title.toLowerCase().contains(query))
        .map<DesktopItem>(DesktopItem.module)
        .toList();
    final appItems = items
        .where((item) => item.isApp && !pinned.contains(item.id) && matching(item).isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.scrim.withValues(alpha: 0.55),
      // The panel is sized from the window so it never runs off the edge on
      // short or narrow screens.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = math.min(760.0, constraints.maxWidth - 24);
          final maxHeight = math.min(680.0, constraints.maxHeight - 24);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
              child: Material(
                borderRadius: BorderRadius.circular(28),
                color: theme.colorScheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search apps and modules',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: <Widget>[
                        if (pinnedItems.isNotEmpty) ...<Widget>[
                          _LauncherHeader(
                            title: 'Pinned',
                            icon: Icons.push_pin_outlined,
                            trailing: TextButton(
                              onPressed: () {
                                for (final item in pinnedItems) {
                                  ref.read(settingsProvider.notifier).togglePinnedApp(item.id);
                                }
                              },
                              child: const Text('Unpin all'),
                            ),
                          ),
                          _LauncherGrid(items: pinnedItems, onLongPress: _pinMenu),
                        ],
                        if (moduleItems.isNotEmpty) ...<Widget>[
                          const _LauncherHeader(title: 'AeroDesk modules', icon: Icons.apps_outlined),
                          _LauncherGrid(items: moduleItems),
                        ],
                        if (appItems.isNotEmpty) ...<Widget>[
                          _LauncherHeader(
                            title: 'Applications',
                            icon: Icons.android_outlined,
                            trailing: Text('${appItems.length} installed',
                                style: theme.textTheme.bodySmall),
                          ),
                          _LauncherGrid(items: appItems, onLongPress: _pinMenu),
                        ],
                        if (pinnedItems.isEmpty && moduleItems.isEmpty && appItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: Text('Nothing matches your search')),
                          ),
                        const _LauncherNote(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Future<void> _pinMenu(DesktopItem item) async {
    final notifier = ref.read(settingsProvider.notifier);
    final selection = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(80, 80, 80, 80),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: notifier.isPinned(item.id) ? 'unpin' : 'pin',
          child: Text(notifier.isPinned(item.id) ? 'Unpin from launcher' : 'Pin to launcher'),
        ),
        const PopupMenuItem<String>(value: 'info', child: Text('App info')),
      ],
    );
    if (selection == null) return;
    switch (selection) {
      case 'pin':
      case 'unpin':
        notifier.togglePinnedApp(item.id);
      case 'info':
        const AppsService().openAppInfo(item.id);
    }
  }
}

class _LauncherHeader extends StatelessWidget {
  const _LauncherHeader({required this.title, required this.icon, this.trailing});

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4, right: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          // Section titles ellipsise so the trailing action stays reachable.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _LauncherGrid extends ConsumerWidget {
  const _LauncherGrid({required this.items, this.onLongPress});

  final List<DesktopItem> items;
  final ValueChanged<DesktopItem>? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 104,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(context, ref, item),
          onLongPress: onLongPress == null ? null : () => onLongPress!(item),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (item.iconBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(item.iconBytes!, width: 40, height: 40, gaplessPlayback: true),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                  ),
                  child: Icon(item.icon, size: 22, color: theme.colorScheme.primary),
                ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }

  void _open(BuildContext context, WidgetRef ref, DesktopItem item) {
    Navigator.of(context).maybePop();
    if (item.isApp) {
      rememberRecentApp(ref, item.id);
      const AppsService().launchApp(item.id);
      return;
    }
    ref.read(windowsProvider.notifier).open(item.id, ref.read(activeWorkspaceProvider));
  }
}

/// Honest note about where installed applications are shown.
///
/// Android has no public API that lets one app host another app's Activity, so
/// installed apps keep opening in the system while AeroDesk modules run inside
/// AeroDesk windows. Saying so here keeps the claim accurate.
class _LauncherNote extends StatelessWidget {
  const _LauncherNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 4, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AeroDesk modules open in desktop windows. Installed apps start in '
              'the system launcher: Android does not allow one app to embed '
              'another app inside its own window.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
