import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String agentName; // Renamed from company
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String plan;
  final List<String> serviceIds;
  final bool isPinned;
  final String? status; // NEW, PROCESS, APPROVED, REFUSED
  final DateTime createdAt;
  final String? creatorEmail;
  final String? passportNumber;
  final DateTime? dob;

  Customer({
    required this.id,
    required this.name,
    required this.agentName,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    this.plan = 'Standard',
    this.serviceIds = const [],
    this.isPinned = false,
    this.status,
    required this.createdAt,
    this.creatorEmail,
    this.passportNumber,
    this.dob,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'agentName': agentName,
      'company': agentName, // Keep company for backward compatibility if needed
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'plan': plan,
      'serviceIds': serviceIds,
      'labelIds': serviceIds,
      'isPinned': isPinned,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'creatorEmail': creatorEmail,
      'passportNumber': passportNumber,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
    };
  }

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      agentName: data['agentName'] ?? data['company'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',
      plan: data['plan'] ?? 'Standard',
      serviceIds: data['serviceIds'] != null
          ? List<String>.from(data['serviceIds'])
          : (data['labelIds'] != null
                ? List<String>.from(data['labelIds'])
                : (data['labelId'] != null ? [data['labelId']] : [])),
      isPinned: data['isPinned'] ?? false,
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorEmail: data['creatorEmail'],
      passportNumber: data['passportNumber'],
      dob: (data['dob'] as Timestamp?)?.toDate(),
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? agentName,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? plan,
    List<String>? serviceIds,
    bool? isPinned,
    String? status,
    DateTime? createdAt,
    String? creatorEmail,
    String? passportNumber,
    DateTime? dob,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      agentName: agentName ?? this.agentName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      plan: plan ?? this.plan,
      serviceIds: serviceIds ?? this.serviceIds,
      isPinned: isPinned ?? this.isPinned,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      passportNumber: passportNumber ?? this.passportNumber,
      dob: dob ?? this.dob,
    );
  }
}
