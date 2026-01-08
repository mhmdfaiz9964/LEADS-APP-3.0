import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String serviceName;
  final double cost;
  final double sellAmount;
  final String status;
  final String customerId;
  final String customerName;
  final DateTime createdAt;
  final String creatorEmail;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.serviceName,
    required this.cost,
    required this.sellAmount,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.createdAt,
    required this.creatorEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'serviceName': serviceName,
      'cost': cost,
      'sellAmount': sellAmount,
      'status': status,
      'customerId': customerId,
      'customerName': customerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'creatorEmail': creatorEmail,
    };
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      serviceName: data['serviceName'] ?? data['productName'] ?? '',
      cost: (data['cost'] ?? data['price'] ?? 0.0).toDouble(),
      sellAmount: (data['sellAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'NEW',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorEmail: data['creatorEmail'] ?? '',
    );
  }
}
