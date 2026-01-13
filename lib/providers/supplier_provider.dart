// File: lib/providers/supplier_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';
import '../services/firebase_service.dart';

class SupplierProvider with ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _isLoading = false;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  SupplierProvider() {
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('suppliers')
          .orderBy('createdAt', descending: true)
          .get();

      _suppliers = snapshot.docs
          .map((doc) => Supplier.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading suppliers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier({
    required String name,
    required String address,
    String? phone,
    String? email,
    required String createdBy,
  }) async {
    try {
      await FirebaseService.firestore.collection('suppliers').add({
        'name': name.trim(),
        'address': address.trim(),
        'phone': phone?.trim(),
        'email': email?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      await loadSuppliers(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding supplier: $e');
      return false;
    }
  }

  Future<bool> updateSupplier({
    required String supplierId,
    required String name,
    required String address,
    String? phone,
    String? email,
  }) async {
    try {
      await FirebaseService.firestore
          .collection('suppliers')
          .doc(supplierId)
          .update({
            'name': name.trim(),
            'address': address.trim(),
            'phone': phone?.trim(),
            'email': email?.trim(),
          });

      await loadSuppliers(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating supplier: $e');
      return false;
    }
  }

  Future<bool> deleteSupplier(String supplierId) async {
    try {
      await FirebaseService.firestore
          .collection('suppliers')
          .doc(supplierId)
          .delete();

      await loadSuppliers(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting supplier: $e');
      return false;
    }
  }

  Supplier? getSupplierById(String id) {
    try {
      return _suppliers.firstWhere((supplier) => supplier.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search suppliers by name
  List<Supplier> searchSuppliers(String query) {
    if (query.isEmpty) return _suppliers;

    return _suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(query.toLowerCase()) ||
          supplier.address.toLowerCase().contains(query.toLowerCase()) ||
          (supplier.phone?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }
}
