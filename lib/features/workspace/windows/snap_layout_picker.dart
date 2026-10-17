import 'package:flutter/material.dart';

import '../../../theme/aerodesk_theme.dart';
import 'window_state.dart';

/// Hover panel offering the snap layouts of a window.
class SnapLayoutPicker extends StatelessWidget {
  const SnapLayoutPicker({
    super.key,
    required this.onSelected,
    required this.onDismiss,
  });

  final ValueChanged<WindowSnap> onSelected;
  final VoidCallback onDismiss;

  static const List<WindowSnap> _layouts = <WindowSnap>[
    WindowSnap.left,
    WindowSnap.right,
    WindowSnap.top,
    WindowSnap.bottom,
    WindowSnap.topLeft,
    WindowSnap.topRight,
    WindowSnap.bottomLeft,
    WindowSnap.bottomRight,
    WindowSnap.maximize,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onExit: (_) => onDismiss(),
      child: Material(
        elevation: 8,
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AeroDimens.radiusMd),
        child: Container(
          width: 232,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Snap layouts', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _layouts.map((snap) {
                  return Tooltip(
                    message: snap.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onSelected(snap),
                      child: Container(
                        width: 46,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          color: theme.colorScheme.surfaceContainerLow,
                        ),
                        child: CustomPaint(painter: _SnapPreviewPainter(snap, theme.colorScheme.primary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the small preview rectangle of a snap layout.
class _SnapPreviewPainter extends CustomPainter {
  const _SnapPreviewPainter(this.snap, this.color);

  final WindowSnap snap;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final outer = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    final fill = switch (snap) {
      WindowSnap.none => Rect.zero,
      WindowSnap.left => Rect.fromLTWH(outer.left, outer.top, outer.width / 2, outer.height),
      WindowSnap.right => Rect.fromLTWH(outer.left + outer.width / 2, outer.top, outer.width / 2, outer.height),
      WindowSnap.top => Rect.fromLTWH(outer.left, outer.top, outer.width, outer.height / 2),
      WindowSnap.bottom => Rect.fromLTWH(outer.left, outer.top + outer.height / 2, outer.width, outer.height / 2),
      WindowSnap.topLeft => Rect.fromLTWH(outer.left, outer.top, outer.width / 2, outer.height / 2),
      WindowSnap.topRight => Rect.fromLTWH(
          outer.left + outer.width / 2,
          outer.top,
          outer.width / 2,
          outer.height / 2,
        ),
      WindowSnap.bottomLeft => Rect.fromLTWH(
          outer.left,
          outer.top + outer.height / 2,
          outer.width / 2,
          outer.height / 2,
        ),
      WindowSnap.bottomRight => Rect.fromLTWH(
          outer.left + outer.width / 2,
          outer.top + outer.height / 2,
          outer.width / 2,
          outer.height / 2,
        ),
      WindowSnap.maximize => outer,
    };
    if (snap == WindowSnap.maximize) {
      final stroke = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(outer, stroke);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(fill, const Radius.circular(2)), paint);
  }

  @override
  bool shouldRepaint(_SnapPreviewPainter oldDelegate) => oldDelegate.snap != snap;
}
