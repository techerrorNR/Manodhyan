import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/note_storage_service.dart';

class NotesController extends ChangeNotifier {
  final _uuid = const Uuid();
  List<NoteModel> _notes = [];
  Future<void>? _initialization;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  bool isLoading = true;
  Object? loadError;

  List<NoteModel> get notes {
    final sorted = [..._notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  Future<void> initialize() => _initialization ??= _load();

  Future<void> _load() async {
    isLoading = true;
    loadError = null;
    _notify();
    try {
      _notes = await NoteStorageService.load();
    } catch (error) {
      loadError = error;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> reload() async {
    await _pending;
    _initialization = null;
    await initialize();
  }

  Future<void> saveNote({
    NoteModel? existing,
    required String title,
    required String body,
  }) => _enqueue(() async {
    if (title.trim().isEmpty && body.trim().isEmpty) {
      throw ArgumentError('Write a title or a note first');
    }
    final now = DateTime.now();
    final note = NoteModel(
      id: existing?.id ?? _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled note' : title.trim(),
      body: body.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final updated = [..._notes];
    final index = updated.indexWhere((item) => item.id == note.id);
    if (index < 0) {
      updated.add(note);
    } else {
      updated[index] = note;
    }
    await NoteStorageService.save(updated);
    _notes = updated;
    _notify();
  });

  Future<void> deleteNote(String id) => _enqueue(() async {
    final updated = _notes.where((note) => note.id != id).toList();
    await NoteStorageService.save(updated);
    _notes = updated;
    _notify();
  });

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _pending.then((_) async {
      await initialize();
      if (loadError != null) {
        throw StateError('Reload saved notes before making changes');
      }
      await action();
    });
    // One failed write must not prevent later saves, or publish an unsaved change.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
