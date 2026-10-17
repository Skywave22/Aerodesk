import 'package:flutter/material.dart';

import '../../../core/models/file_entry.dart';
import '../../../core/utils/formatting.dart';

/// One row in the AeroFiles list.
class FileListTile extends StatelessWidget {
  const FileListTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final FileEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = entry.isFolder ? 'Folder' : _describe(entry);
    return ListTile(
      selected: selected,
      leading: Icon(_iconFor(entry), color: selected ? theme.colorScheme.primary : null),
      title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: entry.isFolder ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _describe(FileEntry entry) {
    final parts = <String>[if (entry.extension.isNotEmpty) entry.extension.toUpperCase()];
    parts.add(formatBytes(entry.size));
    if (entry.modified != null) {
      final modified = entry.modified!;
      parts.add('${modified.day.toString().padLeft(2, '0')}.${modified.month.toString().padLeft(2, '0')}.${modified.year}');
    }
    return parts.join(' · ');
  }

  static IconData _iconFor(FileEntry entry) {
    if (entry.isFolder) return Icons.folder_outlined;
    switch (entry.extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return Icons.image_outlined;
      case 'mp4':
      case 'mkv':
      case 'webm':
      case 'avi':
        return Icons.movie_outlined;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
      case 'flac':
        return Icons.music_note_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_outlined;
      case 'apk':
        return Icons.android_outlined;
      case 'txt':
      case 'md':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
