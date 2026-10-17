import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/aero_constants.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/widgets/aero_empty_state.dart';

/// One note kept on the device.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updated,
  });

  final String id;
  final String title;
  final String body;
  final int updated;

  Note copyWith({String? title, String? body, int? updated}) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      updated: updated ?? this.updated,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'updated': updated,
      };

  static Note fromJson(Map<String, dynamic> json) {
    return Note(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Untitled',
      body: (json['body'] as String?) ?? '',
      updated: (json['updated'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Stores notes in SharedPreferences as a JSON array.
class NotesNotifier extends Notifier<List<Note>> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<Note> build() {
    final raw = _prefs.getString(AeroConstants.prefsKeyNotes);
    if (raw == null || raw.isEmpty) return const <Note>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((entry) => Note.fromJson(entry.cast<String, dynamic>()))
            .toList();
      }
    } on FormatException {
      // Corrupted payload: start from an empty list.
    }
    return const <Note>[];
  }

  void _persist() {
    _prefs.setString(
      AeroConstants.prefsKeyNotes,
      jsonEncode(state.map((note) => note.toJson()).toList()),
    );
  }

  /// Creates a note and returns its id.
  String create() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(id: id, title: 'Untitled note', body: '', updated: now);
    state = <Note>[note, ...state];
    _persist();
    return id;
  }

  void update(String id, {String? title, String? body}) {
    state = state
        .map((note) => note.id == id
            ? note.copyWith(title: title, body: body, updated: DateTime.now().millisecondsSinceEpoch)
            : note)
        .toList();
    _persist();
  }

  void delete(String id) {
    state = state.where((note) => note.id != id).toList();
    _persist();
  }
}

/// All notes, newest first.
final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

/// Id of the note shown in the editor, or null for the "no selection" state.
final activeNoteProvider = StateProvider<String?>((ref) => null);

/// Notes module: a two-pane editor for device-local notes.
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _loadedNoteId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _loadNote(Note note) {
    _titleController.text = note.title;
    _bodyController.text = note.body;
    _loadedNoteId = note.id;
  }

  void _save() {
    final id = _loadedNoteId;
    if (id == null) return;
    ref.read(notesProvider.notifier).update(
          id,
          title: _titleController.text.trim().isEmpty ? 'Untitled note' : _titleController.text.trim(),
          body: _bodyController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final activeId = ref.watch(activeNoteProvider);
    Note? active;
    for (final note in notes) {
      if (note.id == activeId) {
        active = note;
        break;
      }
    }

    if (active != null && _loadedNoteId != active.id) {
      final pending = active;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadNote(pending));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPane = constraints.maxWidth >= 640;
        final list = _NotesList(
          notes: notes,
          activeId: activeId,
          onSelected: (id) => ref.read(activeNoteProvider.notifier).state = id,
          onCreate: () {
            final id = ref.read(notesProvider.notifier).create();
            ref.read(activeNoteProvider.notifier).state = id;
          },
          onDelete: (id) {
            ref.read(notesProvider.notifier).delete(id);
            if (ref.read(activeNoteProvider) == id) {
              ref.read(activeNoteProvider.notifier).state = null;
            }
            _loadedNoteId = null;
          },
        );

        if (!twoPane) {
          return Column(
            children: <Widget>[
              Expanded(child: list),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: 280, child: list),
            const VerticalDivider(width: 1),
            Expanded(child: _buildEditor(active)),
          ],
        );
      },
    );
  }

  Widget _buildEditor(Note? note) {
    if (note == null) {
      return const AeroEmptyState(
        icon: Icons.note_add_outlined,
        title: 'No note selected',
        message: 'Create a note or pick one from the list.',
        compact: true,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(borderSide: BorderSide.none),
              filled: false,
            ),
            onChanged: (_) => _save(),
          ),
          const Divider(height: 1),
          Expanded(
            child: TextField(
              controller: _bodyController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Write something…',
                border: OutlineInputBorder(borderSide: BorderSide.none),
                filled: false,
              ),
              onChanged: (_) => _save(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    required this.notes,
    required this.activeId,
    required this.onSelected,
    required this.onCreate,
    required this.onDelete,
  });

  final List<Note> notes;
  final String? activeId;
  final ValueChanged<String> onSelected;
  final VoidCallback onCreate;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Expanded(child: Text('Notes', style: theme.textTheme.titleMedium)),
              IconButton(
                tooltip: 'New note',
                onPressed: onCreate,
                icon: const Icon(Icons.note_add_outlined),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: notes.isEmpty
              ? const AeroEmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'No notes yet',
                  message: 'Notes stay on this device.',
                  compact: true,
                )
              : ListView.separated(
                  itemCount: notes.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      selected: note.id == activeId,
                      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        note.body.isEmpty ? 'Empty note' : note.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Delete note',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => onDelete(note.id),
                      ),
                      onTap: () => onSelected(note.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
