// File: lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String transactionCurrency;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.transactionCurrency,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      transactionCurrency: data['transactionCurrency'] ?? 'USD',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'transactionCurrency': transactionCurrency,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
