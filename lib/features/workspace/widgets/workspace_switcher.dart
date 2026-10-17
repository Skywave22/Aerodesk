import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/aero_constants.dart';
import '../windows/window_manager.dart';

/// Row of virtual workspace chips.
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final active = ref.watch(activeWorkspaceProvider);
    final windows = ref.watch(windowsProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(AeroConstants.workspaceCount, (index) {
        final count = windows.where((window) => window.workspace == index).length;
        final selected = index == active;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ChoiceChip(
            label: Text('${index + 1}'),
            tooltip: count == 0
                ? 'Workspace ${index + 1}'
                : 'Workspace ${index + 1} · $count ${count == 1 ? 'window' : 'windows'}',
            selected: selected,
            showCheckmark: false,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => ref.read(activeWorkspaceProvider.notifier).select(index),
          ),
        );
      }),
    );
  }
}
