import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final String targetId;
  final String targetType; // 'LEAD' or 'CUSTOMER'
  final String? creatorEmail;

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.targetId,
    required this.targetType,
    this.creatorEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'targetId': targetId,
      'targetType': targetType,
      'creatorEmail': creatorEmail,
    };
  }

  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      creatorEmail: data['creatorEmail'],
    );
  }
}
