import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;
import '../models/whatsapp_message_model.dart';

class WhatsAppService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _baseUrl = "https://www.wasenderapi.com/api";

  Future<String?> _getApiKey() async {
    try {
      final doc = await _db
          .collection('settings')
          .doc('whatsapp_api')
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('apiKey')) {
          return data['apiKey'] as String?;
        } else {
          print(
            "WhatsApp API key document exists but 'apiKey' field is missing.",
          );
        }
      } else {
        print(
          "WhatsApp API key document 'settings/whatsapp_api' not found in Firestore.",
        );
      }
      return null;
    } catch (e) {
      print("Error fetching WhatsApp API key from Firestore: $e");
      return null;
    }
  }

  Future<String?> uploadMedia(File file, {Function(double)? onProgress}) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null) return null;

      final url = Uri.parse("$_baseUrl/upload");

      // Determine content type using path package for consistency
      final extension = p.extension(file.path).toLowerCase();
      String mimetype = 'image/jpeg';
      if (extension == '.png')
        mimetype = 'image/png';
      else if (extension == '.gif')
        mimetype = 'image/gif';
      else if (extension == '.webp')
        mimetype = 'image/webp';
      else if (extension == '.pdf')
        mimetype = 'application/pdf';

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // Construct Data URL scheme as recommended
      final dataUrl = "data:$mimetype;base64,$base64String";

      if (onProgress != null) onProgress(0.5); // Simulated progress point

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"base64": dataUrl}),
      );

      if (onProgress != null) onProgress(1.0);

      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return responseData['publicUrl'];
      } else {
        print("Base64 Upload failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error uploading Base64 media to Wasender: $e");
      return null;
    }
  }

  Future<bool> sendMessage({
    required String to,
    required String text,
    String? imageUrl,
    required String senderEmail,
  }) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null) {
        print(
          "WhatsApp API key not found in Firestore (settings/whatsapp_api)",
        );
        return false;
      }

      final payload = {
        "to": to,
        "text": text,
        if (imageUrl != null && imageUrl.isNotEmpty) "imageUrl": imageUrl,
      };

      final response = await http.post(
        Uri.parse("$_baseUrl/send-message"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);
      bool success = responseData['success'] ?? false;
      String status = success ? 'sent' : 'failed';
      String? msgId = success ? responseData['data']['msgId'].toString() : null;

      // Save to history
      await _db.collection('whatsapp_history').add({
        'to': to,
        'text': text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': status,
        'messageId': msgId,
        'senderEmail': senderEmail,
      });

      return success;
    } catch (e) {
      print("Error sending WhatsApp message: $e");
      return false;
    }
  }

  Stream<List<WhatsAppMessage>> getHistory({
    String? senderEmail,
    String? searchQuery,
  }) {
    Query query = _db
        .collection('whatsapp_history')
        .orderBy('timestamp', descending: true);

    if (senderEmail != null) {
      query = query.where('senderEmail', isEqualTo: senderEmail);
    }

    return query.snapshots().map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => WhatsAppMessage.fromFirestore(doc))
          .toList();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        return messages
            .where(
              (m) =>
                  m.to.toLowerCase().contains(lowerQuery) ||
                  m.text.toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
      return messages;
    });
  }

  Future<WhatsAppMessage?> getMessageDetails(String id) async {
    final doc = await _db.collection('whatsapp_history').doc(id).get();
    if (doc.exists) {
      return WhatsAppMessage.fromFirestore(doc);
    }
    return null;
  }
}
