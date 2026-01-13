// File: lib/models/supplier_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  String id;
  String name;
  String address;
  String? phone;
  String? email;
  DateTime createdAt;
  String createdBy;

  Supplier({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    required this.createdAt,
    required this.createdBy,
  });

  factory Supplier.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Supplier(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'],
      email: data['email'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  @override
  String toString() => name;
}
