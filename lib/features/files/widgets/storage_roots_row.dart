import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/files_service.dart';
import '../files_page.dart';

/// Chips that jump between the storage roots the app can read.
class StorageRootsRow extends ConsumerWidget {
  const StorageRootsRow({super.key, required this.currentPath, required this.onNavigate});

  final String currentPath;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roots = ref.watch(filesRootsProvider).valueOrNull ?? const <StorageRoot>[];
    if (roots.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: roots.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final root = roots[index];
          final selected = root.path == currentPath;
          return ChoiceChip(
            selected: selected,
            avatar: Icon(
              root.primary ? Icons.sd_storage_outlined : Icons.folder_outlined,
              size: 16,
            ),
            label: Text(root.label),
            tooltip: '${root.path} · ${root.writable ? 'writable' : 'read only'}',
            onSelected: (_) => onNavigate(root.path),
          );
        },
      ),
    );
  }
}
