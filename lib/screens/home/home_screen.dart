import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/note_service.dart';
import '../../models/note.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  late final AuthService _authService;
  late final NoteService _noteService;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  
  String? _editingNoteId;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _noteService = NoteService();
  }
  
  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _showNoteDialog({Note? note}) {
    _editingNoteId = note?.id;
    _titleController.text = note?.title ?? '';
    _noteController.text = note?.content ?? '';
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              note == null ? 'Add Note' : 'Edit Note',
              style: context.displayLarge.copyWith(fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter note title',
                    ),
                    maxLength: 100,
                    style: context.bodyLarge,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: context.mediumSpacing),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Enter your note here',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    maxLength: 1000,
                    style: context.bodyMedium,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_noteController.text.length}/1000',
                    style: context.bodySmall.copyWith(
                      color: _noteController.text.length > 1000
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: _isLoading ||
                        _titleController.text.trim().isEmpty ||
                        _noteController.text.trim().isEmpty
                    ? null
                    : () async {
                        if (_titleController.text.trim().isEmpty ||
                            _noteController.text.trim().isEmpty) {
                          _showErrorSnackBar('Please fill in all fields');
                          return;
                        }

                        setState(() => _isLoading = true);

                        try {
                          final newNote = Note(
                            id: _editingNoteId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            title: _titleController.text.trim(),
                            content: _noteController.text.trim(),
                          );

                          final userId = user?.uid;
                          if (userId == null) {
                            throw 'User not authenticated';
                          }

                          if (_editingNoteId == null) {
                            await _noteService.addNote(userId, newNote);
                          } else {
                            await _noteService.updateNote(userId, newNote);
                          }

                          if (!mounted) return;
                          
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Note ${_editingNoteId == null ? 'added' : 'updated'} successfully'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(note == null ? 'ADD' : 'UPDATE'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'DELETE',
              style: context.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);
        await _noteService.deleteNote(user!.uid, noteId);
        _showSuccessSnackBar('Note deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete note. Please try again.');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      // Within a week
      return '${DateFormat('EEEE, h:mm a').format(date)}';
    } else if (date.year == now.year) {
      // This year
      return DateFormat('MMM d • h:mm a').format(date);
    } else {
      // Older dates
      return DateFormat('MMM d, y • h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Notes',
          style: context.displayLarge.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: context.appBarElevation,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _authService.signOut,
            tooltip: 'Sign out',
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
      body: StreamBuilder<List<Note>>(
        stream: _noteService.getNotesStream(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 80,
                      color: Theme.of(context).hintColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No notes yet',
                      style: context.displayMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the + button to create your first note',
                      style: context.bodyLarge?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                margin: EdgeInsets.only(bottom: context.mediumSpacing),
                elevation: context.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showNoteDialog(note: note);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: context.displayMedium.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _deleteNote(note.id),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              tooltip: 'Delete note',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.content,
                          style: context.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatDate(note.updatedAt),
                          style: context.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        tooltip: 'Add new note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
