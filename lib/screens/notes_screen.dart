import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  final String targetId;
  final String targetType;
  final String targetName;

  const NotesScreen({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  void _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final note = Note(
        id: '',
        content: _noteController.text.trim(),
        createdAt: DateTime.now(),
        targetId: widget.targetId,
        targetType: widget.targetType,
        creatorEmail: FirebaseAuth.instance.currentUser?.email,
      );
      await DatabaseService().addNote(note);
      _noteController.clear();
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notes - ${widget.targetName}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF0046FF),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.targetName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_note,
                        color: Color(0xFF0046FF),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d, yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Past Notes List
                  StreamBuilder<List<Note>>(
                    stream: DatabaseService().getNotesByTarget(
                      widget.targetId,
                      widget.targetType,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final notes = snapshot.data!;
                      return Column(
                        children: notes
                            .map((note) => _buildNoteItem(note))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  TextField(
                    controller: _noteController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "Enter your note here...",
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.mic,
                      color: AppTheme.secondaryOrange,
                      size: 32,
                    ),
                    onPressed: () {
                      // TODO: Implement Voice-to-Text
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(Note note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM d, yyyy').format(note.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
