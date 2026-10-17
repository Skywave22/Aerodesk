import 'dart:io';

import 'package:aerodesk/core/models/file_entry.dart';
import 'package:aerodesk/core/services/files_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late FilesService service;

  setUp(() {
    root = Directory.systemTemp.createTempSync('aerodesk_files_test');
    service = const FilesService();
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  String pathOf(String name) => '${root.path}/$name';

  test('lists folders before files and sorts by name', () async {
    File(pathOf('beta.txt')).writeAsStringSync('beta');
    File(pathOf('alpha.txt')).writeAsStringSync('alpha');
    Directory(pathOf('zeta')).createSync();

    final entries = await service.listDirectory(root.path);

    expect(entries.length, 3);
    expect(entries.first.name, 'zeta');
    expect(entries.first.isFolder, isTrue);
    expect(entries.first.kind, FileKind.folder);
    expect(entries[1].name, 'alpha.txt');
    expect(entries[2].name, 'beta.txt');
    expect(entries[1].extension, 'txt');
    expect(entries[1].size, greaterThan(0));
  });

  test('creates folders and rejects unsafe names', () async {
    expect((await service.createDirectory(root.path, 'Notes')).ok, isTrue);
    expect(Directory(pathOf('Notes')).existsSync(), isTrue);
    expect((await service.createDirectory(root.path, 'Notes')).result, FilesResult.alreadyExists);
    expect((await service.createDirectory(root.path, '  ')).result, FilesResult.error);
    expect((await service.createDirectory(root.path, '../escape')).result, FilesResult.error);
  });

  test('creates files', () async {
    expect((await service.createFile(root.path, 'todo.md')).ok, isTrue);
    expect(File(pathOf('todo.md')).existsSync(), isTrue);
  });

  test('renames entries', () async {
    await service.createFile(root.path, 'old.txt');
    expect((await service.rename(pathOf('old.txt'), 'new.txt')).ok, isTrue);
    expect(File(pathOf('new.txt')).existsSync(), isTrue);
    expect(File(pathOf('old.txt')).existsSync(), isFalse);
    expect((await service.rename(pathOf('new.txt'), '')).result, FilesResult.error);
  });

  test('deletes files and folders recursively', () async {
    await service.createDirectory(root.path, 'folder');
    await service.createFile(pathOf('folder'), 'inner.txt');
    expect((await service.delete(pathOf('folder'))).ok, isTrue);
    expect(Directory(pathOf('folder')).existsSync(), isFalse);

    await service.createFile(root.path, 'loose.txt');
    expect((await service.delete(pathOf('loose.txt'))).ok, isTrue);
    expect(File(pathOf('loose.txt')).existsSync(), isFalse);
  });

  test('copies files into another folder', () async {
    await service.createFile(root.path, 'source.txt');
    await service.createDirectory(root.path, 'target');
    expect((await service.copy(pathOf('source.txt'), pathOf('target'))).ok, isTrue);
    expect(File(pathOf('source.txt')).existsSync(), isTrue);
    expect(File(pathOf('target/source.txt')).existsSync(), isTrue);
  });

  test('copies folders recursively', () async {
    await service.createDirectory(root.path, 'source');
    await service.createFile(pathOf('source'), 'inner.txt');
    await service.createDirectory(root.path, 'target');
    expect((await service.copy(pathOf('source'), pathOf('target'))).ok, isTrue);
    expect(File(pathOf('target/source/inner.txt')).existsSync(), isTrue);
  });

  test('moves entries and refuses a move onto itself', () async {
    await service.createFile(root.path, 'moving.txt');
    await service.createDirectory(root.path, 'target');
    expect((await service.move(pathOf('moving.txt'), pathOf('target'))).ok, isTrue);
    expect(File(pathOf('moving.txt')).existsSync(), isFalse);
    expect(File(pathOf('target/moving.txt')).existsSync(), isTrue);

    await service.createFile(pathOf('target'), 'inner.txt');
    final sameFolder = await service.move(pathOf('target/inner.txt'), pathOf('target'));
    expect(sameFolder.result, FilesResult.alreadyExists);
    expect(File(pathOf('target/inner.txt')).existsSync(), isTrue);
  });

  test('returns an empty list for a missing folder', () async {
    expect(await service.listDirectory(pathOf('missing')), isEmpty);
  });
}
