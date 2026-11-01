import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusjoy/controllers/notes_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'notes survive reopening, edits keep identity, and deletion persists',
    () async {
      final controller = NotesController();
      await controller.saveNote(title: 'Plan', body: 'Read for twenty minutes');
      final original = controller.notes.single;
      controller.dispose();
      final reopened = NotesController();
      await reopened.initialize();
      expect(reopened.notes.single.id, original.id);
      expect(reopened.notes.single.body, 'Read for twenty minutes');
      await reopened.saveNote(
        existing: reopened.notes.single,
        title: 'Updated plan',
        body: 'Read for thirty minutes',
      );
      expect(reopened.notes.single.createdAt, original.createdAt);
      expect(reopened.notes.single.id, original.id);
      reopened.dispose();
      final afterEdit = NotesController();
      await afterEdit.initialize();
      expect(afterEdit.notes.single.title, 'Updated plan');
      await afterEdit.deleteNote(original.id);
      afterEdit.dispose();
      final afterDelete = NotesController();
      await afterDelete.initialize();
      expect(afterDelete.notes, isEmpty);
      afterDelete.dispose();
    },
  );

  test('concurrent note saves retain both notes', () async {
    final controller = NotesController();
    await Future.wait([
      controller.saveNote(title: 'First', body: 'A'),
      controller.saveNote(title: 'Second', body: 'B'),
    ]);
    expect(controller.notes.map((note) => note.title).toSet(), {
      'First',
      'Second',
    });
    final reopened = NotesController();
    await reopened.initialize();
    expect(reopened.notes, hasLength(2));
    controller.dispose();
    reopened.dispose();
  });

  test('an invalid save does not prevent a later valid save', () async {
    final controller = NotesController();
    await expectLater(
      controller.saveNote(title: ' ', body: '\n'),
      throwsArgumentError,
    );
    await controller.saveNote(title: '', body: 'A useful thought');
    expect(controller.notes.single.title, 'Untitled note');
    expect(controller.notes.single.body, 'A useful thought');
    controller.dispose();
  });

  test('unreadable saved notes cannot be silently overwritten', () async {
    SharedPreferences.setMockInitialValues({
      'manodhyan_notes_v1': '{invalid json',
    });
    final controller = NotesController();
    await controller.initialize();
    expect(controller.loadError, isNotNull);
    await expectLater(
      controller.saveNote(title: 'New', body: 'Would replace data'),
      throwsStateError,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('manodhyan_notes_v1'), '{invalid json');
    controller.dispose();
  });
}
