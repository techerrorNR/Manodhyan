import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NoteStorageService {
  static const _key = 'manodhyan_notes_v1';

  static Future<List<NoteModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('Invalid notes data');
    // Do not silently discard malformed notes and overwrite the saved collection.
    return decoded
        .map(
          (entry) => NoteModel.fromMap(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
  }

  static Future<void> save(List<NoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _key,
      jsonEncode(notes.map((note) => note.toMap()).toList()),
    );
    if (!saved) throw StateError('Unable to save notes');
  }
}
