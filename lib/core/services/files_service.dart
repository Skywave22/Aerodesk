import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/file_entry.dart';
import 'apps_service.dart';

/// A storage root the user can browse in AeroFiles.
class StorageRoot {
  const StorageRoot({
    required this.path,
    required this.label,
    required this.writable,
    required this.primary,
  });

  final String path;
  final String label;
  final bool writable;
  final bool primary;
}

/// Result of a filesystem operation.
enum FilesResult { success, notFound, permissionDenied, alreadyExists, error }

/// Outcome detail of a filesystem operation.
class FilesOperation {
  const FilesOperation(this.result, {this.message = ''});

  final FilesResult result;
  final String message;

  bool get ok => result == FilesResult.success;
}

/// Reads and writes files in shared storage through supported Dart APIs.
///
/// Only public APIs are used: `dart:io` plus `path_provider` for app-scoped
/// directories. Operations on Android shared storage require the user-granted
/// "All files access" permission, which this service checks before writing.
class FilesService {
  const FilesService();

  static const AppsService _apps = AppsService();

  /// Directory listing, folders first, case-insensitive by name.
  Future<List<FileEntry>> listDirectory(String path) async {
    try {
      final directory = Directory(path);
      final entries = <FileEntry>[];
      await for (final entity in directory.list(followLinks: false)) {
        final stat = await entity.stat();
        final isDirectory = stat.type == FileSystemEntityType.directory;
        final isFile = stat.type == FileSystemEntityType.file;
        final segments = entity.uri.pathSegments.where((segment) => segment.isNotEmpty);
        entries.add(
          FileEntry(
            path: entity.path,
            name: segments.isEmpty ? entity.path : segments.last,
            kind: isDirectory
                ? FileKind.folder
                : isFile
                    ? FileKind.file
                    : FileKind.unknown,
            size: isDirectory ? null : stat.size,
            modified: stat.modified,
          ),
        );
      }
      entries.sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return entries;
    } on FileSystemException {
      return const <FileEntry>[];
    }
  }

  Future<bool> hasAllFilesAccess() => _apps.hasAllFilesAccess();

  Future<bool> requestAllFilesAccess() => _apps.requestAllFilesAccess();

  Future<FilesOperation> createDirectory(String parentPath, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const FilesOperation(FilesResult.error, message: 'Enter a folder name');
    if (trimmed.contains('/') || trimmed.contains('..')) {
      return const FilesOperation(FilesResult.error, message: 'Invalid folder name');
    }
    final target = _join(parentPath, trimmed);
    try {
      final directory = Directory(target);
      if (directory.existsSync()) {
        return const FilesOperation(FilesResult.alreadyExists, message: 'That name already exists');
      }
      await directory.create(recursive: false);
      return const FilesOperation(FilesResult.success);
    } on FileSystemException catch (error) {
      return FilesOperation(_mapError(error), message: error.message);
    }
  }

  Future<FilesOperation> createFile(String parentPath, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const FilesOperation(FilesResult.error, message: 'Enter a file name');
    if (trimmed.contains('/') || trimmed.contains('..')) {
      return const FilesOperation(FilesResult.error, message: 'Invalid file name');
    }
    final target = _join(parentPath, trimmed);
    try {
      final file = File(target);
      if (file.existsSync()) {
        return const FilesOperation(FilesResult.alreadyExists, message: 'That name already exists');
      }
      await file.create(recursive: false);
      return const FilesOperation(FilesResult.success);
    } on FileSystemException catch (error) {
      return FilesOperation(_mapError(error), message: error.message);
    }
  }

  Future<FilesOperation> rename(String path, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return const FilesOperation(FilesResult.error, message: 'Enter a new name');
    if (trimmed.contains('/') || trimmed.contains('..')) {
      return const FilesOperation(FilesResult.error, message: 'Invalid name');
    }
    final parent = _parentOf(path);
    final target = _join(parent, trimmed);
    try {
      final entity = _entityOf(path);
      await entity.rename(target);
      return const FilesOperation(FilesResult.success);
    } on FileSystemException catch (error) {
      return FilesOperation(_mapError(error), message: error.message);
    }
  }

  Future<FilesOperation> delete(String path) async {
    try {
      final entity = _entityOf(path);
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else {
        await entity.delete();
      }
      return const FilesOperation(FilesResult.success);
    } on FileSystemException catch (error) {
      return FilesOperation(_mapError(error), message: error.message);
    }
  }

  Future<FilesOperation> move(String source, String destinationDirectory) {
    return _copyOrMove(source, destinationDirectory, move: true);
  }

  Future<FilesOperation> copy(String source, String destinationDirectory) {
    return _copyOrMove(source, destinationDirectory, move: false);
  }

  Future<FilesOperation> _copyOrMove(String source, String destinationDirectory, {required bool move}) async {
    try {
      final entity = _entityOf(source);
      final name = _basename(source);
      final destinationPath = _join(destinationDirectory, name);
      if (_isSamePath(source, destinationPath)) {
        return const FilesOperation(FilesResult.alreadyExists, message: 'Destination is the same folder');
      }
      if (entity is Directory) {
        if (move) {
          await entity.rename(destinationPath);
        } else {
          await _copyDirectory(entity, Directory(destinationPath));
        }
      } else if (entity is File) {
        if (move) {
          await entity.rename(destinationPath);
        } else {
          await entity.copy(destinationPath);
        }
      } else {
        return const FilesOperation(FilesResult.notFound, message: 'Item no longer exists');
      }
      return const FilesOperation(FilesResult.success);
    } on FileSystemException catch (error) {
      return FilesOperation(_mapError(error), message: error.message);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = _basename(entity.path);
      final target = _join(destination.path, name);
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(target));
      } else if (entity is File) {
        await entity.copy(target);
      }
    }
  }

  Future<bool> openFile(String path) => _apps.openFile(path);

  /// Storage roots the app can browse without elevated permissions.
  Future<List<StorageRoot>> usableRoots() async {
    final roots = <StorageRoot>[];
    try {
      final appDir = await getApplicationDocumentsDirectory();
      roots.add(StorageRoot(path: appDir.path, label: 'App storage', writable: true, primary: true));
      final tempDir = await getTemporaryDirectory();
      roots.add(StorageRoot(path: tempDir.path, label: 'Temporary files', writable: true, primary: false));
    } on MissingPluginException {
      // App-scoped directories are unavailable (for example in unit tests);
      // shared storage roots are still reported below when permitted.
    }
    final external = Directory('/storage/emulated/0');
    if (await _apps.hasAllFilesAccess() && external.existsSync()) {
      roots.add(StorageRoot(path: external.path, label: 'Internal storage', writable: true, primary: true));
    }
    for (final volume in await _apps.storageVolumes()) {
      if (roots.any((root) => root.path == volume.path)) continue;
      if (!Directory(volume.path).existsSync()) continue;
      roots.add(
        StorageRoot(
          path: volume.path,
          label: volume.label,
          writable: volume.primary || !volume.removable,
          primary: volume.primary,
        ),
      );
    }
    return roots;
  }

  bool _isSamePath(String a, String b) {
    final normalizedA = a.endsWith(Platform.pathSeparator) ? a.substring(0, a.length - 1) : a;
    return normalizedA == b;
  }

  FileSystemEntity _entityOf(String path) {
    if (Directory(path).existsSync()) return Directory(path);
    if (File(path).existsSync()) return File(path);
    return File(path);
  }

  String _basename(String path) {
    final separator = Platform.pathSeparator;
    final trimmed = path.endsWith(separator) ? path.substring(0, path.length - 1) : path;
    final index = trimmed.lastIndexOf(separator);
    return index == -1 ? trimmed : trimmed.substring(index + 1);
  }

  String _parentOf(String path) {
    final separator = Platform.pathSeparator;
    final trimmed = path.endsWith(separator) ? path.substring(0, path.length - 1) : path;
    final index = trimmed.lastIndexOf(separator);
    if (index <= 0) return separator;
    return trimmed.substring(0, index);
  }

  String _join(String parent, String child) {
    final separator = Platform.pathSeparator;
    return parent.endsWith(separator) ? '$parent$child' : '$parent$separator$child';
  }

  FilesResult _mapError(FileSystemException error) {
    final os = error.osError;
    if (os == null) return FilesResult.error;
    switch (os.errorCode) {
      case 13:
      case 30:
        return FilesResult.permissionDenied;
      case 2:
      case 20:
        return FilesResult.notFound;
      case 17:
        return FilesResult.alreadyExists;
      default:
        return FilesResult.error;
    }
  }
}
