import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String productName;
  final int quantity;
  final double price;
  final String status;
  final String customerId;
  final String customerName;
  final DateTime createdAt;
  final String creatorEmail;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.createdAt,
    required this.creatorEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'productName': productName,
      'quantity': quantity,
      'price': price,
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
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'ORDER',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorEmail: data['creatorEmail'] ?? '',
    );
  }
}
