import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppMessage {
  final String id;
  final String to;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final String status; // 'sent', 'failed', 'in_progress'
  final String? messageId;
  final String senderEmail;

  WhatsAppMessage({
    required this.id,
    required this.to,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    required this.status,
    this.messageId,
    required this.senderEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'to': to,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'status': status,
      'messageId': messageId,
      'senderEmail': senderEmail,
    };
  }

  factory WhatsAppMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WhatsAppMessage(
      id: doc.id,
      to: data['to'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'sent',
      messageId: data['messageId'],
      senderEmail: data['senderEmail'] ?? '',
    );
  }
}
