// File: lib/providers/buy_order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/buy_order_model.dart';
import '../services/firebase_service.dart';

class BuyOrderProvider with ChangeNotifier {
  List<BuyOrder> _buyOrders = [];
  bool _isLoading = false;

  List<BuyOrder> get buyOrders => _buyOrders;
  bool get isLoading => _isLoading;

  // Getters for dashboard stats
  int get totalOrders => _buyOrders.length;
  int get pendingOrders => _buyOrders.where((order) => order.isPending).length;
  int get completedOrders =>
      _buyOrders.where((order) => order.isCompleted).length;
  double get totalCost {
    return _buyOrders
        .where((order) => order.isCompleted && order.paid)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  BuyOrderProvider() {
    loadBuyOrders();
  }

  Future<void> loadBuyOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('buy_orders')
          .orderBy('date', descending: true)
          .get();

      _buyOrders = snapshot.docs
          .map((doc) => BuyOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading buy orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBuyOrder({
    required DateTime date,
    required String supplierName,
    required String supplierAddress,
    required String productId,
    required String productName,
    required String productCode,
    required double quantity,
    required double rate,
    required String createdBy,
  }) async {
    try {
      final totalAmount = quantity * rate;

      await FirebaseService.firestore.collection('buy_orders').add({
        'date': Timestamp.fromDate(date),
        'supplierName': supplierName.trim(),
        'supplierAddress': supplierAddress.trim(),
        'productId': productId,
        'productName': productName,
        'productCode': productCode,
        'quantity': quantity,
        'rate': rate,
        'totalAmount': totalAmount,
        'status': 'pending',
        'paid': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding buy order: $e');
      return false;
    }
  }

  Future<bool> deleteBuyOrder(String orderId) async {
    try {
      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .delete();

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting buy order: $e');
      return false;
    }
  }

  // Filter methods for reports
  List<BuyOrder> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _buyOrders.where((order) {
      return order.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          order.date.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
  }

  List<BuyOrder> getPendingOrders() {
    return _buyOrders.where((order) => order.isPending).toList();
  }

  List<BuyOrder> getCompletedOrders() {
    return _buyOrders.where((order) => order.isCompleted).toList();
  }

  // Calculate total inventory cost (for profit calculation)
  double getInventoryValue() {
    return _buyOrders
        .where((order) => order.isCompleted && order.paid)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  // Add these methods to BuyOrderProvider class
  Future<bool> updateBuyOrder({
    required String orderId,
    required DateTime date,
    required String supplierName,
    required String supplierAddress,
    required String productId,
    required String productName,
    required String productCode,
    required double quantity,
    required double rate,
  }) async {
    try {
      final totalAmount = quantity * rate;

      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .update({
            'date': Timestamp.fromDate(date),
            'supplierName': supplierName.trim(),
            'supplierAddress': supplierAddress.trim(),
            'productId': productId,
            'productName': productName,
            'productCode': productCode,
            'quantity': quantity,
            'rate': rate,
            'totalAmount': totalAmount,
          });

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating buy order: $e');
      return false;
    }
  }

  // Add partial payment
  Future<bool> addPartialPayment({
    required String orderId,
    required double amount,
    required String note,
  }) async {
    try {
      final order = _buyOrders.firstWhere((order) => order.id == orderId);
      final newPaidAmount = order.paidAmount + amount;
      final isFullyPaid = newPaidAmount >= order.totalAmount;

      Map<String, dynamic> updates = {
        'paidAmount': newPaidAmount,
        'paymentDate': FieldValue.serverTimestamp(),
      };

      // If fully paid, update status
      if (isFullyPaid) {
        updates['paid'] = true;
        updates['status'] = 'completed';
      }

      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .update(updates);

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding partial payment: $e');
      return false;
    }
  }

  // Record payment transaction in subcollection
  Future<bool> recordPaymentTransaction({
    required String orderId,
    required double amount,
    required String paymentMethod,
    String? note,
    String? referenceNumber,
  }) async {
    try {
      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .add({
            'amount': amount,
            'paymentMethod': paymentMethod,
            'note': note,
            'referenceNumber': referenceNumber,
            'date': FieldValue.serverTimestamp(),
            'createdBy': 'system',
          });

      return true;
    } catch (e) {
      if (kDebugMode) print('Error recording payment transaction: $e');
      return false;
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(String orderId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID for editing/deleting
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting payment history: $e');
      return [];
    }
  }

  // Update payment transaction
  Future<bool> updatePaymentTransaction({
    required String orderId,
    required String transactionId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? note,
  }) async {
    try {
      // Get old amount to adjust order total
      final oldTransaction = await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .doc(transactionId)
          .get();

      final oldAmount = oldTransaction.exists
          ? (oldTransaction.data()!['amount'] as num).toDouble()
          : 0.0;

      final amountDifference = amount - oldAmount;

      // Update transaction
      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .doc(transactionId)
          .update({
            'amount': amount,
            'paymentMethod': paymentMethod,
            'referenceNumber': referenceNumber,
            'note': note,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update order's paid amount
      if (amountDifference != 0) {
        final orderDoc = await FirebaseService.firestore
            .collection('buy_orders')
            .doc(orderId)
            .get();

        if (orderDoc.exists) {
          final currentAmount = (orderDoc.data()!['paidAmount'] as num)
              .toDouble();
          final newAmount = currentAmount + amountDifference;
          final totalAmount = (orderDoc.data()!['totalAmount'] as num)
              .toDouble();

          await FirebaseService.firestore
              .collection('buy_orders')
              .doc(orderId)
              .update({
                'paidAmount': newAmount,
                'paid': newAmount >= totalAmount,
                'status': newAmount >= totalAmount ? 'completed' : 'pending',
              });
        }
      }

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating payment transaction: $e');
      return false;
    }
  }

  // Delete payment transaction
  Future<bool> deletePaymentTransaction({
    required String orderId,
    required String transactionId,
  }) async {
    try {
      // Get the transaction to know the amount
      final transactionDoc = await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) return false;

      final amount = (transactionDoc.data()!['amount'] as num).toDouble();

      // Delete the transaction
      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .doc(transactionId)
          .delete();

      // Update the order's paid amount
      final orderDoc = await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final currentAmount = (orderDoc.data()!['paidAmount'] as num)
            .toDouble();
        final newAmount = currentAmount - amount;
        final totalAmount = (orderDoc.data()!['totalAmount'] as num).toDouble();

        await FirebaseService.firestore
            .collection('buy_orders')
            .doc(orderId)
            .update({
              'paidAmount': newAmount,
              'paid': newAmount >= totalAmount,
              'status': newAmount >= totalAmount ? 'completed' : 'pending',
            });
      }

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting payment transaction: $e');
      return false;
    }
  }

  // Update the existing updateBuyOrderStatus to handle partial payments
  Future<bool> updateBuyOrderStatus({
    required String orderId,
    double? paymentAmount, // NEW: Optional payment amount
    bool? paid,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (paid != null && paymentAmount != null) {
        updates['paid'] = paid;
        updates['paidAmount'] = paymentAmount;
        updates['paymentDate'] = FieldValue.serverTimestamp();

        // If paid amount meets or exceeds total, mark as completed
        final order = _buyOrders.firstWhere((order) => order.id == orderId);
        if (paymentAmount >= order.totalAmount) {
          updates['status'] = 'completed';
        } else {
          updates['status'] = 'pending';
        }
      }

      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .update(updates);

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating buy order: $e');
      return false;
    }
  }

  // Update the existing undoPayment method
  Future<bool> undoPayment(String orderId, {double? amount}) async {
    try {
      final order = _buyOrders.firstWhere((order) => order.id == orderId);
      double newPaidAmount = order.paidAmount;

      if (amount != null) {
        // Partial undo
        newPaidAmount = (order.paidAmount - amount).clamp(
          0.0,
          order.totalAmount,
        );
      } else {
        // Full undo
        newPaidAmount = 0.0;
      }

      Map<String, dynamic> updates = {
        'paidAmount': newPaidAmount,
        'paid': newPaidAmount >= order.totalAmount,
      };

      // If payment is no longer full, reset completion status
      if (newPaidAmount < order.totalAmount) {
        updates['status'] = 'pending';
      }

      await FirebaseService.firestore
          .collection('buy_orders')
          .doc(orderId)
          .update(updates);

      await loadBuyOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error undoing payment: $e');
      return false;
    }
  }
}
