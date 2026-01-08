import 'package:cloud_firestore/cloud_firestore.dart';

class Lead {
  final String id;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String? status; // 'NEW', 'PENDING', 'CLOSED'
  final List<String> labelIds; // IDs of the assigned labels
  final bool isPinned;
  final DateTime createdAt;
  final String? creatorEmail;

  Lead({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    this.status,
    this.labelIds = const [],
    this.isPinned = false,
    required this.createdAt,
    this.creatorEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'status': status,
      'labelIds': labelIds,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
      'creatorEmail': creatorEmail,
    };
  }

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lead(
      id: doc.id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',
      status: data['status'],
      labelIds: data['labelIds'] != null
          ? List<String>.from(data['labelIds'])
          : (data['labelId'] != null ? [data['labelId']] : []),
      isPinned: data['isPinned'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorEmail: data['creatorEmail'],
    );
  }
}
