import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final int colorValue;
  final String? creatorEmail;

  ServiceModel({
    required this.id,
    required this.name,
    required this.colorValue,
    this.creatorEmail,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'colorValue': colorValue,
      'creatorEmail': creatorEmail,
    };
  }

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      colorValue: data['colorValue'] ?? 0xFF000000,
      creatorEmail: data['creatorEmail'],
    );
  }
}
