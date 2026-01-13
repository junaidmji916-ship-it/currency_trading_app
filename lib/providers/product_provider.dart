// File: lib/providers/product_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  ProductProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct({
    required String productCode,
    required String productName,
    String? description,
    required String createdBy,
  }) async {
    try {
      await FirebaseService.firestore.collection('products').add({
        'productCode': productCode.toUpperCase().trim(),
        'productName': productName.trim(),
        'description': description?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      await loadProducts(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct({
    required String productId,
    required String productCode,
    required String productName,
    String? description,
  }) async {
    try {
      await FirebaseService.firestore
          .collection('products')
          .doc(productId)
          .update({
            'productCode': productCode.toUpperCase().trim(),
            'productName': productName.trim(),
            'description': description?.trim(),
          });

      await loadProducts(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await FirebaseService.firestore
          .collection('products')
          .doc(productId)
          .delete();

      await loadProducts(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting product: $e');
      return false;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}
