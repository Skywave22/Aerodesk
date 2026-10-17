import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/constants/aero_constants.dart';
import '../device/device_page.dart';
import '../files/files_page.dart';
import '../settings/settings_page.dart';
import 'desktop/desktop_view.dart';
import 'dock/aerodesk_dock.dart';
import 'dock/app_launcher.dart';
import 'widgets/workspace_top_bar.dart';
import 'windows/window_manager.dart';

/// Root shell of AeroDesk: navigation, desktop and windows.
class AeroDeskShell extends ConsumerStatefulWidget {
  const AeroDeskShell({super.key});

  @override
  ConsumerState<AeroDeskShell> createState() => _AeroDeskShellState();
}

class _AeroDeskShellState extends ConsumerState<AeroDeskShell> {
  ShellSection _section = ShellSection.workspace;

  /// Width at which the navigation rail replaces the bottom navigation bar.
  static const double _railBreakpoint = 840;

  /// Width at which the navigation rail shows labels.
  static const double _extendedRailBreakpoint = 1180;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= _railBreakpoint;
    final extended = width >= _extendedRailBreakpoint;

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: <Widget>[
                if (useRail) _buildRail(extended),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      const WorkspaceTopBar(),
                      Expanded(child: _buildSection(useRail)),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: useRail ? null : _buildBottomBar(),
          ),
        ),
      ),
    );
  }

  Map<ShortcutActivator, Intent> get _shortcuts {
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.escape): const CloseWindowIntent(),
      const SingleActivator(LogicalKeyboardKey.f11): const ToggleMaximizeIntent(),
      const SingleActivator(LogicalKeyboardKey.keyW, control: true): const CloseWindowIntent(),
      const SingleActivator(LogicalKeyboardKey.keyM, control: true): const MinimizeWindowIntent(),
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): const OpenLauncherIntent(),
      const SingleActivator(LogicalKeyboardKey.bracketRight, control: true): const NextWorkspaceIntent(),
      const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true): const PreviousWorkspaceIntent(),
    };
    for (var index = 0; index < AeroConstants.workspaceCount; index++) {
      final key = LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + index);
      shortcuts[SingleActivator(key, control: true)] = SelectWorkspaceIntent(index);
    }
    return shortcuts;
  }

  Map<Type, Action<Intent>> get _actions {
    return <Type, Action<Intent>>{
      SelectWorkspaceIntent: CallbackAction<SelectWorkspaceIntent>(
        onInvoke: (intent) => ref.read(activeWorkspaceProvider.notifier).select(intent.index),
      ),
      NextWorkspaceIntent: CallbackAction<NextWorkspaceIntent>(
        onInvoke: (_) => ref.read(activeWorkspaceProvider.notifier).next(),
      ),
      PreviousWorkspaceIntent: CallbackAction<PreviousWorkspaceIntent>(
        onInvoke: (_) => ref.read(activeWorkspaceProvider.notifier).previous(),
      ),
      OpenLauncherIntent: CallbackAction<OpenLauncherIntent>(
        onInvoke: (_) {
          if (_isTextInputFocused()) return null;
          showAppLauncher(context);
          return null;
        },
      ),
      CloseWindowIntent: CallbackAction<CloseWindowIntent>(
        onInvoke: (_) {
          if (_isTextInputFocused()) return null;
          final focused = ref.read(focusedWindowProvider);
          if (focused != null) ref.read(windowsProvider.notifier).close(focused);
          return null;
        },
      ),
      MinimizeWindowIntent: CallbackAction<MinimizeWindowIntent>(
        onInvoke: (_) {
          final focused = ref.read(focusedWindowProvider);
          if (focused != null) ref.read(windowsProvider.notifier).toggleMinimize(focused);
          return null;
        },
      ),
      ToggleMaximizeIntent: CallbackAction<ToggleMaximizeIntent>(
        onInvoke: (_) {
          final focused = ref.read(focusedWindowProvider);
          if (focused == null) return null;
          final bounds = _desktopBounds();
          if (bounds == null) return null;
          ref.read(windowsProvider.notifier).toggleMaximize(focused, bounds);
          return null;
        },
      ),
    };
  }

  /// Desktop area of the workspace section, used by keyboard snap actions.
  Rect? _desktopBounds() {
    final box = _sectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return Offset.zero & box.size;
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (context == null) return false;
    return context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  final GlobalKey _sectionKey = GlobalKey();

  Widget _buildRail(bool extended) {
    return NavigationRail(
      extended: extended,
      minWidth: extended ? 180 : 72,
      selectedIndex: ShellSection.values.indexOf(_section),
      onDestinationSelected: (index) => setState(() => _section = ShellSection.values[index]),
      leading: extended
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Icon(Icons.desktop_windows, color: theme.colorScheme.primary);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(AeroConstants.appName, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            )
          : null,
      destinations: <NavigationRailDestination>[
        for (final section in ShellSection.values)
          NavigationRailDestination(
            icon: Icon(section.icon),
            selectedIcon: Icon(section.selectedIcon),
            label: Text(section.label),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return NavigationBar(
      selectedIndex: ShellSection.values.indexOf(_section),
      onDestinationSelected: (index) => setState(() => _section = ShellSection.values[index]),
      destinations: <Widget>[
        for (final section in ShellSection.values)
          NavigationDestination(icon: Icon(section.icon), selectedIcon: Icon(section.selectedIcon), label: section.label),
      ],
    );
  }

  Widget _buildSection(bool useRail) {
    if (_section == ShellSection.workspace) {
      return _WorkspaceSection(
        sectionKey: _sectionKey,
        bottomInset: useRail ? 0.0 : MediaQuery.paddingOf(context).bottom + 80,
      );
    }
    return KeyedSubtree(
      key: _sectionKey,
      child: switch (_section) {
        ShellSection.workspace => const SizedBox.shrink(),
        ShellSection.files => const FilesPage(),
        ShellSection.settings => const SettingsPage(),
        ShellSection.device => const DevicePage(),
      },
    );
  }
}

class SelectWorkspaceIntent extends Intent {
  const SelectWorkspaceIntent(this.index);

  final int index;
}

class NextWorkspaceIntent extends Intent {
  const NextWorkspaceIntent();
}

class PreviousWorkspaceIntent extends Intent {
  const PreviousWorkspaceIntent();
}

class CloseWindowIntent extends Intent {
  const CloseWindowIntent();
}

class MinimizeWindowIntent extends Intent {
  const MinimizeWindowIntent();
}

class ToggleMaximizeIntent extends Intent {
  const ToggleMaximizeIntent();
}

class OpenLauncherIntent extends Intent {
  const OpenLauncherIntent();
}

/// Workspace section: desktop plus the dock overlay.
class _WorkspaceSection extends StatelessWidget {
  const _WorkspaceSection({required this.sectionKey, required this.bottomInset});

  final GlobalKey sectionKey;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: sectionKey,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: DesktopView()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AeroDeskDock(bottomInset: bottomInset),
          ),
        ],
      ),
    );
  }
}
