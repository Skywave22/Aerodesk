import 'package:flutter/material.dart';

import '../../../core/utils/formatting.dart';

/// Horizontal breadcrumb showing the current folder path.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    super.key,
    required this.path,
    required this.onNavigate,
    this.rootLabel = 'Storage',
  });

  final String path;
  final ValueChanged<String> onNavigate;
  final String rootLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (path.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(rootLabel, style: theme.textTheme.titleSmall),
      );
    }
    final segments = path.split('/').where((segment) => segment.isNotEmpty).toList();
    final items = <_Crumb>[
      _Crumb('/', rootLabel),
      for (var i = 0; i < segments.length; i++)
        _Crumb('/${segments.sublist(0, i + 1).join('/')}', segments[i]),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (var i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              onPressed: () => onNavigate(items[i].path),
              child: Text(items[i].label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }
}

/// Human readable path used in the details sheet.
String describePath(String path) {
  if (path.isEmpty) return 'Storage';
  final segments = path.split('/').where((segment) => segment.isNotEmpty).toList();
  return '/${segments.join('/')}';
}

class _Crumb {
  const _Crumb(this.path, this.label);

  final String path;
  final String label;
}

/// Convenience wrapper so other files can format sizes consistently.
String fileSizeLabel(int? bytes) => formatBytes(bytes);
