import 'package:flutter/material.dart';

import '../../theme/aerodesk_theme.dart';

/// A rounded surface panel used across AeroDesk.
class AeroPanel extends StatelessWidget {
  const AeroPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AeroDimens.panelPadding),
    this.radius = AeroDimens.radiusLg,
    this.color,
    this.borderColor,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null || onSecondaryTap != null) {
      panel = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        child: panel,
      );
    }

    if (margin != null) {
      panel = Padding(padding: margin!, child: panel);
    }

    return panel;
  }
}
