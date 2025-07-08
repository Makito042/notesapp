import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get notes stream for the current user
  Stream<List<Note>> getNotesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Note.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  // Add a new note
  Future<void> addNote(String userId, Note note) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(note.toMap());
  }
  
  // Update an existing note
  Future<void> updateNote(String userId, Note note) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.id)
        .update(note.toMap());
  }
  
  // Delete a note
  Future<void> deleteNote(String userId, String noteId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}
