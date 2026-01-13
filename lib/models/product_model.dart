// File: lib/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id;
  String productCode;
  String productName;
  String? description;
  DateTime createdAt;
  String createdBy;

  Product({
    required this.id,
    required this.productCode,
    required this.productName,
    this.description,
    required this.createdAt,
    required this.createdBy,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      productCode: data['productCode'] ?? '',
      productName: data['productName'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productCode': productCode,
      'productName': productName,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
