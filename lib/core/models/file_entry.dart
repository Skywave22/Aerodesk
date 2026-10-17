import 'dart:io';

/// The kind of a filesystem entry.
enum FileKind { folder, file, unknown }

/// A single file or folder shown in AeroFiles.
class FileEntry {
  const FileEntry({
    required this.path,
    required this.name,
    required this.kind,
    this.size,
    this.modified,
  });

  final String path;
  final String name;
  final FileKind kind;
  final int? size;
  final DateTime? modified;

  bool get isFolder => kind == FileKind.folder;

  bool get isHidden => name.startsWith('.');

  String get extension {
    if (kind != FileKind.file || !name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }

  /// Builds an entry from a filesystem entity, tolerating stat failures.
  static Future<FileEntry> fromEntity(FileSystemEntity entity) async {
    final segments = entity.uri.pathSegments.where((segment) => segment.isNotEmpty);
    final name = segments.isEmpty ? entity.path : segments.last;
    try {
      final stat = await entity.stat();
      final isDirectory = stat.type == FileSystemEntityType.directory;
      final isFile = stat.type == FileSystemEntityType.file;
      return FileEntry(
        path: entity.path,
        name: name,
        kind: isDirectory
            ? FileKind.folder
            : isFile
                ? FileKind.file
                : FileKind.unknown,
        size: isDirectory ? null : stat.size,
        modified: stat.modified,
      );
    } on FileSystemException {
      final isDirectory = entity is Directory;
      return FileEntry(
        path: entity.path,
        name: name,
        kind: isDirectory ? FileKind.folder : FileKind.file,
      );
    }
  }
}
