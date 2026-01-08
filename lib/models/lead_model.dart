import 'package:cloud_firestore/cloud_firestore.dart';

class Lead {
  final String id;
  final String name;
  final String agentName; // Renamed from company
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String? status; // 'NEW', 'PENDING', 'CLOSED'
  final List<String> serviceIds; // IDs of the assigned services
  final bool isPinned;
  final DateTime createdAt;
  final String? creatorEmail;
  final String? passportNumber;
  final DateTime? dob;

  Lead({
    required this.id,
    required this.name,
    required this.agentName,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    this.status,
    this.serviceIds = const [],
    this.isPinned = false,
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
      'status': status,
      'serviceIds': serviceIds,
      'labelIds':
          serviceIds, // Keep labelIds for backward compatibility in Firestore
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
      'creatorEmail': creatorEmail,
      'passportNumber': passportNumber,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
    };
  }

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lead(
      id: doc.id,
      name: data['name'] ?? '',
      agentName: data['agentName'] ?? data['company'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',
      status: data['status'],
      serviceIds: data['serviceIds'] != null
          ? List<String>.from(data['serviceIds'])
          : (data['labelIds'] != null
                ? List<String>.from(data['labelIds'])
                : (data['labelId'] != null ? [data['labelId']] : [])),
      isPinned: data['isPinned'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorEmail: data['creatorEmail'],
      passportNumber: data['passportNumber'],
      dob: (data['dob'] as Timestamp?)?.toDate(),
    );
  }
}
