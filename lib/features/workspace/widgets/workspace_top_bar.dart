import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/aero_constants.dart';
import '../../../core/services/apps_service.dart';
import '../../../core/services/clock_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatting.dart';
import '../windows/window_manager.dart';
import 'workspace_switcher.dart';

/// Top bar of the AeroDesk shell: title, workspaces, clock and status.
///
/// The layout is responsive: optional rows drop out on narrow windows so the
/// bar never overflows on phones.
class WorkspaceTopBar extends ConsumerWidget {
  const WorkspaceTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final clock = ref.watch(clockProvider);
    final focused = ref.watch(focusedWindowProvider);
    final workspace = ref.watch(activeWorkspaceProvider);
    final openWindows = ref.watch(windowsProvider).where((window) => window.workspace == workspace);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.75),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showTagline = width >= 760;
          final showWindowsButton = width >= 900;
          final showAccessChip = width >= 560;

          return Row(
            children: <Widget>[
              Icon(Icons.desktop_windows, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                AeroConstants.appName,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (showTagline) ...<Widget>[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    AeroConstants.appTagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ] else
                const Spacer(),
              const Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: WorkspaceSwitcher(),
                ),
              ),
              const SizedBox(width: 4),
              if (focused != null && showWindowsButton)
                TextButton(
                  onPressed: () => ref.read(windowsProvider.notifier).minimizeAll(workspace),
                  child: Text('${openWindows.length} open'),
                ),
              if (showAccessChip) ...<Widget>[
                const _AllFilesAccessChip(),
                const SizedBox(width: 4),
              ],
              Text(
                clock.when(
                  data: (value) => formatTimeOfDay(value, use24Hour: MediaQuery.of(context).alwaysUse24HourFormat),
                  loading: () => '--:--',
                  error: (error, stackTrace) => '--:--',
                ),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Toggle theme',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  final next = settings.themeMode == AeroThemeMode.dark ? AeroThemeMode.light : AeroThemeMode.dark;
                  ref.read(settingsProvider.notifier).setThemeMode(next);
                },
                icon: Icon(
                  settings.themeMode == AeroThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shows whether AeroFiles may write to shared storage.
class _AllFilesAccessChip extends ConsumerWidget {
  const _AllFilesAccessChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final granted = ref.watch(allFilesAccessProvider).valueOrNull ?? false;
    return Tooltip(
      message: granted ? 'All files access granted' : 'All files access not granted · tap to request',
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(
          granted ? Icons.folder_open : Icons.lock_outline,
          size: 16,
          color: granted ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
        label: Text(granted ? 'Files' : 'No access'),
        onPressed: () async {
          if (granted) return;
          const service = AppsService();
          await service.requestAllFilesAccess();
          ref.invalidate(allFilesAccessProvider);
        },
      ),
    );
  }
}
