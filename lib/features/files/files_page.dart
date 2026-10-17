import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/file_entry.dart';
import '../../core/services/apps_service.dart';
import '../../core/services/files_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/aero_empty_state.dart';
import '../../core/widgets/aero_panel.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/file_list_tile.dart';
import 'widgets/storage_roots_row.dart';

/// Storage roots the app can read.
final filesRootsProvider = FutureProvider<List<StorageRoot>>((ref) {
  return const FilesService().usableRoots();
});

/// Current folder; empty string means "show the roots".
final filesPathProvider = StateProvider<String>((ref) => '');

/// Clipboard used by copy and move.
final filesClipboardProvider = StateProvider<({String path, bool move})?>((ref) => null);

/// Entries of the current folder.
final filesEntriesProvider = FutureProvider<List<FileEntry>>((ref) async {
  final path = ref.watch(filesPathProvider);
  final roots = await ref.watch(filesRootsProvider.future);
  if (path.isEmpty) {
    return roots
        .map(
          (root) => FileEntry(
            path: root.path,
            name: root.label,
            kind: FileKind.folder,
            modified: null,
          ),
        )
        .toList();
  }
  return const FilesService().listDirectory(path);
});

/// Selected entries, keyed by path.
final filesSelectionProvider = StateProvider<Set<String>>((ref) => <String>{});

/// Text typed into the in-folder search field.
final filesQueryProvider = StateProvider<String>((ref) => '');

/// True when the folder is shown as a grid instead of a list.
final filesGridViewProvider = StateProvider<bool>((ref) => false);

/// Sort order of the entries in the current folder.
final filesSortProvider = StateProvider<IconSort>((ref) => IconSort.name);

/// Sorts [entries] by [sort].
List<FileEntry> sortEntries(List<FileEntry> entries, IconSort sort) {
  final sorted = List<FileEntry>.of(entries);
  switch (sort) {
    case IconSort.name:
      sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case IconSort.type:
      sorted.sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        final byExtension = a.extension.compareTo(b.extension);
        return byExtension != 0 ? byExtension : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    case IconSort.size:
      sorted.sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return (b.size ?? 0).compareTo(a.size ?? 0);
      });
    case IconSort.modified:
      sorted.sort((a, b) {
        final left = a.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
  }
  return sorted;
}

/// AeroFiles: browse and manage files with public Android APIs only.
class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final path = ref.watch(filesPathProvider);
    final query = ref.watch(filesQueryProvider);
    final entries = ref.watch(filesEntriesProvider);
    final selection = ref.watch(filesSelectionProvider);
    final clipboard = ref.watch(filesClipboardProvider);
    final access = ref.watch(allFilesAccessProvider).valueOrNull ?? false;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: BreadcrumbBar(
                      path: path,
                      onNavigate: (value) {
                        ref.read(filesPathProvider.notifier).state = value;
                        ref.read(filesSelectionProvider.notifier).state = <String>{};
                        ref.read(filesQueryProvider.notifier).state = '';
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: ref.watch(filesGridViewProvider) ? 'Switch to list' : 'Switch to grid',
                    onPressed: () {
                      final current = ref.read(filesGridViewProvider);
                      ref.read(filesGridViewProvider.notifier).state = !current;
                    },
                    icon: Icon(ref.watch(filesGridViewProvider) ? Icons.view_list_outlined : Icons.grid_view_outlined),
                  ),
                  PopupMenuButton<IconSort>(
                    tooltip: 'Sort by ${sortLabel(ref.watch(filesSortProvider))}',
                    icon: const Icon(Icons.sort),
                    initialValue: ref.watch(filesSortProvider),
                    onSelected: (value) => ref.read(filesSortProvider.notifier).state = value,
                    itemBuilder: (context) => <PopupMenuEntry<IconSort>>[
                      for (final option in IconSort.values)
                        PopupMenuItem<IconSort>(
                          value: option,
                          child: Text(sortLabel(option)),
                        ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'New folder',
                    onPressed: () => _createFolder(context, ref, path),
                    icon: const Icon(Icons.create_new_folder_outlined),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => ref.invalidate(filesEntriesProvider),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (path.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search in this folder',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => ref.read(filesQueryProvider.notifier).state = '',
                          ),
                  ),
                  onChanged: (value) => ref.read(filesQueryProvider.notifier).state = value,
                ),
              ],
              const SizedBox(height: 8),
              StorageRootsRow(
                currentPath: path,
                onNavigate: (value) {
                  ref.read(filesPathProvider.notifier).state = value;
                  ref.read(filesSelectionProvider.notifier).state = <String>{};
                },
              ),
              if (!access && path.startsWith('/storage')) ...<Widget>[
                const SizedBox(height: 8),
                _AccessBanner(),
              ],
              if (clipboard != null) ...<Widget>[
                const SizedBox(height: 8),
                _ClipboardBanner(
                  path: clipboard.path,
                  move: clipboard.move,
                  destination: path,
                  onCancel: () => ref.read(filesClipboardProvider.notifier).state = null,
                ),
              ],
              if (selection.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                _SelectionBar(
                  count: selection.length,
                  destination: path,
                  onClear: () => ref.read(filesSelectionProvider.notifier).state = <String>{},
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: entries.when(
            data: (items) {
              final search = query.trim().toLowerCase();
              final visible = sortEntries(
                search.isEmpty
                    ? items
                    : items.where((entry) => entry.name.toLowerCase().contains(search)).toList(),
                ref.watch(filesSortProvider),
              );
              if (items.isEmpty) {
                return AeroEmptyState(
                  icon: path.isEmpty ? Icons.sd_storage_outlined : Icons.folder_open_outlined,
                  title: path.isEmpty ? 'No storage available' : 'This folder is empty',
                  message: path.isEmpty
                      ? 'Grant all files access to browse shared storage.'
                      : 'Create a folder or copy something here.',
                  compact: true,
                );
              }
              if (visible.isEmpty) {
                return const AeroEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No matches',
                  message: 'No item in this folder matches your search.',
                  compact: true,
                );
              }
              if (ref.watch(filesGridViewProvider)) {
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _FileGridTile(
                    entry: visible[index],
                    selected: selection.contains(visible[index].path),
                    onTap: () => _openEntry(context, ref, visible[index], selection),
                    onLongPress: () => _showEntryMenu(context, ref, visible[index]),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = visible[index];
                  return FileListTile(
                    entry: entry,
                    selected: selection.contains(entry.path),
                    onTap: () => _openEntry(context, ref, entry, selection),
                    onLongPress: () => _showEntryMenu(context, ref, entry),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => AeroEmptyState(
              icon: Icons.error_outline,
              title: 'Could not read this folder',
              message: '$error',
              compact: true,
              action: TextButton(
                onPressed: () => ref.invalidate(filesEntriesProvider),
                child: const Text('Try again'),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            path.isEmpty ? 'Select a storage root' : describePath(path),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  /// Opens a folder, toggles the selection or opens a file.
  void _openEntry(BuildContext context, WidgetRef ref, FileEntry entry, Set<String> selection) {
    if (selection.isNotEmpty) {
      _toggleSelection(ref, entry.path);
      return;
    }
    if (entry.isFolder) {
      ref.read(filesPathProvider.notifier).state = entry.path;
      ref.read(filesQueryProvider.notifier).state = '';
      return;
    }
    _openFile(context, ref, entry);
  }

  void _toggleSelection(WidgetRef ref, String path) {
    final current = Set<String>.from(ref.read(filesSelectionProvider));
    if (!current.remove(path)) current.add(path);
    ref.read(filesSelectionProvider.notifier).state = current;
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref, FileEntry entry) async {
    final opened = await const AppsService().openFile(entry.path);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No app can open ${entry.name}')),
    );
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref, String parent) async {
    if (parent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a storage root first')),
      );
      return;
    }
    final name = await _promptText(context, title: 'New folder', hint: 'Folder name');
    if (name == null || name.isEmpty || !context.mounted) return;
    final result = await const FilesService().createDirectory(parent, name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.ok ? 'Folder created' : result.message)),
    );
    ref.invalidate(filesEntriesProvider);
  }

  Future<void> _showEntryMenu(BuildContext context, WidgetRef ref, FileEntry entry) async {
    final theme = Theme.of(context);
    final selection = ref.read(filesSelectionProvider);
    final target = selection.contains(entry.path) ? selection.length : 1;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(entry.name),
              subtitle: Text(
                '${entry.isFolder ? 'Folder' : formatBytes(entry.size)} · ${describePath(entry.path)}',
              ),
            ),
            const Divider(height: 1),
            if (!entry.isFolder)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open with'),
                onTap: () => Navigator.of(context).pop('open'),
              ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: Text(target == 1 ? 'Copy' : 'Copy $target items'),
              onTap: () => Navigator.of(context).pop('copy'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: Text(target == 1 ? 'Move' : 'Move $target items'),
              onTap: () => Navigator.of(context).pop('move'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text(target == 1 ? 'Delete' : 'Delete $target items'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case 'open':
        _openFile(context, ref, entry);
      case 'rename':
        await _rename(context, ref, entry);
      case 'copy':
      case 'move':
        ref.read(filesClipboardProvider.notifier).state = (
          path: entry.path,
          move: action == 'move',
        );
        ref.read(filesSelectionProvider.notifier).state = <String>{entry.path};
      case 'delete':
        await _delete(context, ref, <String>[entry.path]);
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, FileEntry entry) async {
    final name = await _promptText(
      context,
      title: 'Rename',
      hint: 'New name',
      initial: entry.name,
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final result = await const FilesService().rename(entry.path, name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.ok ? 'Renamed' : result.message)),
    );
    ref.invalidate(filesEntriesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, List<String> paths) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(paths.length == 1 ? 'Delete item?' : 'Delete ${paths.length} items?'),
        content: const Text('Deleted items cannot be recovered.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    const service = FilesService();
    var failures = 0;
    for (final path in paths) {
      final result = await service.delete(path);
      if (!result.ok) failures++;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failures == 0 ? 'Deleted' : '$failures item(s) could not be deleted')),
    );
    ref.read(filesSelectionProvider.notifier).state = <String>{};
    ref.invalidate(filesEntriesProvider);
  }

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String hint,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Explains why shared storage needs the all files access permission.
class _AccessBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AeroPanel(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      child: Row(
        children: <Widget>[
          Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AeroFiles can write to shared storage after you grant "All files access".',
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () async {
              await const AppsService().requestAllFilesAccess();
              ref.invalidate(allFilesAccessProvider);
              ref.invalidate(filesRootsProvider);
              ref.invalidate(filesEntriesProvider);
            },
            child: const Text('Grant'),
          ),
        ],
      ),
    );
  }
}

/// Shows the pending copy/move action and its destination.
class _ClipboardBanner extends ConsumerWidget {
  const _ClipboardBanner({
    required this.path,
    required this.move,
    required this.destination,
    required this.onCancel,
  });

  final String path;
  final bool move;
  final String destination;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const service = FilesService();
    return AeroPanel(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Row(
        children: <Widget>[
          Icon(move ? Icons.drive_file_move_outline : Icons.content_copy_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${move ? 'Move' : 'Copy'} ${describePath(path)} → ${destination.isEmpty ? 'no destination' : describePath(destination)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
          FilledButton(
            onPressed: destination.isEmpty
                ? null
                : () async {
                    final result = move ? await service.move(path, destination) : await service.copy(path, destination);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.ok ? 'Done' : result.message)),
                    );
                    ref.read(filesClipboardProvider.notifier).state = null;
                    ref.read(filesSelectionProvider.notifier).state = <String>{};
                    ref.invalidate(filesEntriesProvider);
                  },
            child: Text(move ? 'Move here' : 'Copy here'),
          ),
        ],
      ),
    );
  }
}

/// Toolbar shown while entries are selected.
class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({
    required this.count,
    required this.destination,
    required this.onClear,
  });

  final int count;
  final String destination;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const service = FilesService();
    final selection = ref.watch(filesSelectionProvider);
    return AeroPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Text('$count selected', style: theme.textTheme.labelLarge),
          const Spacer(),
          IconButton(
            tooltip: 'Copy selection here',
            onPressed: destination.isEmpty
                ? null
                : () async {
                    for (final path in selection) {
                      await service.copy(path, destination);
                    }
                    ref.read(filesSelectionProvider.notifier).state = <String>{};
                    ref.invalidate(filesEntriesProvider);
                  },
            icon: const Icon(Icons.content_copy_outlined),
          ),
          IconButton(
            tooltip: 'Move selection here',
            onPressed: destination.isEmpty
                ? null
                : () async {
                    for (final path in selection) {
                      await service.move(path, destination);
                    }
                    ref.read(filesSelectionProvider.notifier).state = <String>{};
                    ref.invalidate(filesEntriesProvider);
                  },
            icon: const Icon(Icons.drive_file_move_outlined),
          ),
          IconButton(
            tooltip: 'Delete selection',
            onPressed: () async {
              for (final path in selection) {
                await service.delete(path);
              }
              ref.read(filesSelectionProvider.notifier).state = <String>{};
              ref.invalidate(filesEntriesProvider);
            },
            icon: const Icon(Icons.delete_outline),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

/// Grid tile used by the AeroFiles grid view.
class _FileGridTile extends StatelessWidget {
  const _FileGridTile({
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final FileEntry entry;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = entry.isFolder ? Icons.folder_outlined : Icons.insert_drive_file_outlined;
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 32,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                entry.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 2),
              Text(
                entry.isFolder ? 'Folder' : formatBytes(entry.size),
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label of a sort option, reusing the settings labels.
String sortLabel(IconSort sort) => sort.label;
