import 'package:flutter/material.dart';

import '../../../core/constants/aero_constants.dart';

/// Where a window is snapped to inside the desktop area.
enum WindowSnap {
  none,
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  maximize;

  String get label => switch (this) {
        none => 'Floating',
        left => 'Left half',
        right => 'Right half',
        top => 'Top half',
        bottom => 'Bottom half',
        topLeft => 'Top left',
        topRight => 'Top right',
        bottomLeft => 'Bottom left',
        bottomRight => 'Bottom right',
        maximize => 'Maximise',
      };

  IconData get icon => switch (this) {
        none => Icons.crop_free,
        left => Icons.vertical_split,
        right => Icons.vertical_split,
        top => Icons.horizontal_split,
        bottom => Icons.horizontal_split,
        topLeft => Icons.crop_square,
        topRight => Icons.crop_square,
        bottomLeft => Icons.crop_square,
        bottomRight => Icons.crop_square,
        maximize => Icons.fullscreen,
      };
}

/// Immutable state of one desktop window.
class AeroWindowModel {
  const AeroWindowModel({
    required this.id,
    required this.moduleId,
    required this.workspace,
    required this.offset,
    required this.size,
    this.snap = WindowSnap.none,
    this.minimized = false,
    this.zIndex = 0,
  });

  /// Unique window id: `<workspace>:<moduleId>`.
  final String id;
  final String moduleId;

  /// Virtual workspace this window lives on (0-based).
  final int workspace;
  final Offset offset;
  final Size size;
  final WindowSnap snap;
  final bool minimized;
  final int zIndex;

  AeroWindowModel copyWith({
    Offset? offset,
    Size? size,
    WindowSnap? snap,
    bool? minimized,
    int? zIndex,
  }) {
    return AeroWindowModel(
      id: id,
      moduleId: moduleId,
      workspace: workspace,
      offset: offset ?? this.offset,
      size: size ?? this.size,
      snap: snap ?? this.snap,
      minimized: minimized ?? this.minimized,
      zIndex: zIndex ?? this.zIndex,
    );
  }

  /// Clamps the window so it always stays reachable inside [bounds].
  AeroWindowModel clampedTo(Rect bounds) {
    final width = size.width.clamp(AeroConstants.minWindowWidth, bounds.width);
    final height = size.height.clamp(AeroConstants.minWindowHeight, bounds.height);
    final x = offset.dx.clamp(
      -(width - AeroConstants.minWindowWidth),
      bounds.width - AeroConstants.minWindowWidth,
    );
    final y = offset.dy.clamp(0.0, bounds.height - AeroConstants.windowTitleBarHeight);
    return copyWith(offset: Offset(x, y), size: Size(width, height));
  }

  /// Applies a snap layout to the window inside [bounds].
  AeroWindowModel snappedTo(WindowSnap target, Rect bounds) {
    if (target == WindowSnap.none) return copyWith(snap: WindowSnap.none);
    if (target == WindowSnap.maximize) {
      return copyWith(
        snap: WindowSnap.maximize,
        offset: Offset.zero,
        size: Size(bounds.width, bounds.height),
      );
    }
    const inset = 8.0;
    final usable = Rect.fromLTWH(
      inset,
      inset,
      (bounds.width - inset * 2).clamp(AeroConstants.minWindowWidth, double.infinity),
      (bounds.height - inset * 2).clamp(AeroConstants.minWindowHeight, double.infinity),
    );
    final halfWidth = usable.width / 2;
    final halfHeight = usable.height / 2;
    final rect = switch (target) {
      WindowSnap.none => usable,
      WindowSnap.left => Rect.fromLTWH(usable.left, usable.top, halfWidth, usable.height),
      WindowSnap.right => Rect.fromLTWH(usable.left + halfWidth, usable.top, halfWidth, usable.height),
      WindowSnap.top => Rect.fromLTWH(usable.left, usable.top, usable.width, halfHeight),
      WindowSnap.bottom => Rect.fromLTWH(usable.left, usable.top + halfHeight, usable.width, halfHeight),
      WindowSnap.topLeft => Rect.fromLTWH(usable.left, usable.top, halfWidth, halfHeight),
      WindowSnap.topRight => Rect.fromLTWH(usable.left + halfWidth, usable.top, halfWidth, halfHeight),
      WindowSnap.bottomLeft => Rect.fromLTWH(usable.left, usable.top + halfHeight, halfWidth, halfHeight),
      WindowSnap.bottomRight => Rect.fromLTWH(
          usable.left + halfWidth,
          usable.top + halfHeight,
          halfWidth,
          halfHeight,
        ),
      WindowSnap.maximize => usable,
    };
    return copyWith(
      snap: target,
      offset: Offset(rect.left, rect.top),
      size: Size(rect.width, rect.height),
    );
  }
}
