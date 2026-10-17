import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/aero_constants.dart';
import 'window_state.dart';

/// Index of the active virtual workspace (0-based).
final activeWorkspaceProvider = NotifierProvider<ActiveWorkspaceNotifier, int>(
  ActiveWorkspaceNotifier.new,
);

class ActiveWorkspaceNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    state = index.clamp(0, AeroConstants.workspaceCount - 1);
  }

  void next() => select(state + 1);

  void previous() => select(state - 1);
}

/// Id of the focused window, or null when the desktop itself has focus.
final focusedWindowProvider = StateProvider<String?>((ref) => null);

/// All open windows, ordered from back to front.
final windowsProvider = NotifierProvider<WindowsNotifier, List<AeroWindowModel>>(
  WindowsNotifier.new,
);

/// Owns the desktop window manager state.
///
/// There is at most one window per module per workspace; opening a module that
/// already has a window focuses (and un-minimises) that window instead.
class WindowsNotifier extends Notifier<List<AeroWindowModel>> {
  static const Size defaultSize = Size(520, 420);

  @override
  List<AeroWindowModel> build() => const <AeroWindowModel>[];

  int get _nextZ => state.isEmpty ? 1 : state.map((w) => w.zIndex).reduce((a, b) => a > b ? a : b) + 1;

  List<AeroWindowModel> visibleIn(int workspace) {
    return state.where((window) => window.workspace == workspace).toList();
  }

  AeroWindowModel? byId(String id) {
    for (final window in state) {
      if (window.id == id) return window;
    }
    return null;
  }

  /// Opens (or focuses) the window of [moduleId] on [workspace].
  void open(String moduleId, int workspace, {Size? size, Offset? offset}) {
    final id = '$workspace:$moduleId';
    final existing = byId(id);
    if (existing != null) {
      state = _map((window) => window.id == id
          ? window.copyWith(minimized: false, zIndex: _nextZ)
          : window);
      ref.read(focusedWindowProvider.notifier).state = id;
      return;
    }
    final index = visibleIn(workspace).length;
    final cascade = Offset(24 + index * 28.0, 24 + index * 28.0);
    final window = AeroWindowModel(
      id: id,
      moduleId: moduleId,
      workspace: workspace,
      offset: offset ?? cascade,
      size: size ?? defaultSize,
      zIndex: _nextZ,
    );
    state = <AeroWindowModel>[...state, window];
    ref.read(focusedWindowProvider.notifier).state = id;
  }

  void close(String id) {
    state = state.where((window) => window.id != id).toList();
    if (ref.read(focusedWindowProvider) == id) {
      final workspace = ref.read(activeWorkspaceProvider);
      final remaining = state.where((window) => window.workspace == workspace);
      ref.read(focusedWindowProvider.notifier).state =
          remaining.isEmpty ? null : remaining.last.id;
    }
  }

  void closeWorkspace(int workspace) {
    state = state.where((window) => window.workspace != workspace).toList();
    ref.read(focusedWindowProvider.notifier).state = null;
  }

  void focus(String id) {
    if (byId(id)?.zIndex == _nextZ) return;
    state = _map((window) => window.id == id ? window.copyWith(zIndex: _nextZ) : window);
    ref.read(focusedWindowProvider.notifier).state = id;
  }

  void toggleMinimize(String id) {
    final window = byId(id);
    if (window == null) return;
    if (window.minimized) {
      focus(id);
      state = _map((item) => item.id == id ? item.copyWith(minimized: false) : item);
      return;
    }
    state = _map((item) => item.id == id ? item.copyWith(minimized: true) : item);
    if (ref.read(focusedWindowProvider) == id) {
      final visible = state.where((item) => item.workspace == window.workspace && !item.minimized);
      ref.read(focusedWindowProvider.notifier).state = visible.isEmpty ? null : visible.last.id;
    }
  }

  void minimizeAll(int workspace) {
    state = _map((window) => window.workspace == workspace ? window.copyWith(minimized: true) : window);
    ref.read(focusedWindowProvider.notifier).state = null;
  }

  /// Moves a window, keeping it inside [bounds].
  void move(String id, Offset delta, Rect bounds) {
    final window = byId(id);
    if (window == null) return;
    final moved = window.copyWith(offset: window.offset + delta);
    state = _replace(id, moved.clampedTo(bounds));
  }

  /// Moves a window to an absolute position inside [bounds].
  void place(String id, Offset position, Rect bounds) {
    final window = byId(id);
    if (window == null) return;
    state = _replace(id, window.copyWith(offset: position).clampedTo(bounds));
  }

  /// Resizes a window, keeping it inside [bounds] and above the minimum size.
  void resize(String id, Size delta, Rect bounds) {
    final window = byId(id);
    if (window == null) return;
    final size = Size(
      window.size.width + delta.width,
      window.size.height + delta.height,
    );
    state = _replace(id, window.copyWith(size: size).clampedTo(bounds));
  }

  void snap(String id, WindowSnap snap, Rect bounds) {
    final window = byId(id);
    if (window == null) return;
    state = _replace(id, window.snappedTo(snap, bounds));
  }

  void toggleMaximize(String id, Rect bounds) {
    final window = byId(id);
    if (window == null) return;
    final target = window.snap == WindowSnap.maximize ? WindowSnap.none : WindowSnap.maximize;
    state = _replace(id, window.snappedTo(target, bounds));
  }

  List<AeroWindowModel> _map(AeroWindowModel Function(AeroWindowModel) transform) {
    return state.map(transform).toList();
  }

  List<AeroWindowModel> _replace(String id, AeroWindowModel window) {
    return _map((item) => item.id == id ? window : item);
  }
}
