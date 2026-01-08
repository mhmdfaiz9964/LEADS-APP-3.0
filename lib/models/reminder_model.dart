import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String title;
  final DateTime date; // Combines date and time
  final bool isCompleted;
  final bool isPinned;
  final String? targetId; // ID of the Lead or Customer
  final String? targetType; // 'LEAD' or 'CUSTOMER'
  final String? creatorEmail;

  Reminder({
    required this.id,
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isPinned = false,
    this.targetId,
    this.targetType,
    this.creatorEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'isPinned': isPinned,
      'targetId': targetId,
      'targetType': targetType,
      'creatorEmail': creatorEmail,
    };
  }

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Reminder(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
      isPinned: data['isPinned'] ?? false,
      targetId: data['targetId'],
      targetType: data['targetType'],
      creatorEmail: data['creatorEmail'],
    );
  }
}
