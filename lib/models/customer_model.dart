import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String plan;
  final List<String> labelIds;
  final bool isPinned;
  final String? status; // ORDER, PAYMENT_APPROVED, PREPARED, DELIVERED
  final DateTime createdAt;
  final String? creatorEmail;

  Customer({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    this.plan = 'Standard',
    this.labelIds = const [],
    this.isPinned = false,
    this.status,
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
      'plan': plan,
      'labelIds': labelIds,
      'isPinned': isPinned,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'creatorEmail': creatorEmail,
    };
  }

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',
      plan: data['plan'] ?? 'Standard',
      labelIds: data['labelIds'] != null
          ? List<String>.from(data['labelIds'])
          : (data['labelId'] != null ? [data['labelId']] : []),
      isPinned: data['isPinned'] ?? false,
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorEmail: data['creatorEmail'],
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? company,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? plan,
    List<String>? labelIds,
    bool? isPinned,
    String? status,
    DateTime? createdAt,
    String? creatorEmail,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      plan: plan ?? this.plan,
      labelIds: labelIds ?? this.labelIds,
      isPinned: isPinned ?? this.isPinned,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      creatorEmail: creatorEmail ?? this.creatorEmail,
    );
  }
}
