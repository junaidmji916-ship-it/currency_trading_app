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
  Future<bool> undoPayment(
    String orderId, {
    double? amount,
    required String note,
  }) async {
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

  Future<bool> updatePayment({
    required String orderId,
    required String paymentId,
    required double newAmount,
    required String newNote,
    required DateTime newDate,
  }) async {
    try {
      final paymentRef = FirebaseFirestore.instance
          .collection('buyOrders')
          .doc(orderId)
          .collection('payments')
          .doc(paymentId);

      await paymentRef.update({
        'amount': newAmount,
        'note': newNote,
        'date': newDate.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating payment: $e');
      return false;
    }
  }

  Future<bool> adjustPaidAmount({
    required String orderId,
    required double adjustment,
  }) async {
    try {
      final orderRef = FirebaseFirestore.instance
          .collection('buyOrders')
          .doc(orderId);

      await orderRef.update({
        'paidAmount': FieldValue.increment(adjustment),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      print('Error adjusting paid amount: $e');
      return false;
    }
  }

  Future<bool> deletePayment({
    required String orderId,
    required String paymentId,
  }) async {
    try {
      final paymentRef = FirebaseFirestore.instance
          .collection('buyOrders')
          .doc(orderId)
          .collection('payments')
          .doc(paymentId);

      // Get payment amount before deleting
      final paymentDoc = await paymentRef.get();
      final amount = paymentDoc.data()?['amount'] ?? 0.0;

      // Delete payment
      await paymentRef.delete();

      // Adjust order's paid amount
      await adjustPaidAmount(
        orderId: orderId,
        adjustment: -amount, // Subtract the deleted amount
      );

      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting payment: $e');
      return false;
    }
  }

  // Add this method to your BuyOrderProvider class
  Future<void> loadBuyOrdersWithPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('buy_orders')
          .orderBy('date', descending: true)
          .get();

      _buyOrders = await Future.wait(
        snapshot.docs.map((doc) async {
          // Load payment transactions
          final paymentSnapshot = await FirebaseService.firestore
              .collection('buy_orders')
              .doc(doc.id)
              .collection('payment_transactions')
              .orderBy('date', descending: true)
              .get();

          // Convert to payment history format
          List<Map<String, dynamic>> paymentHistory = [];
          double totalPaid = 0.0;

          for (var paymentDoc in paymentSnapshot.docs) {
            final paymentData = paymentDoc.data();
            final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
            totalPaid += amount;

            paymentHistory.add({
              'paymentId': paymentDoc.id,
              'amount': amount,
              'date': (paymentData['date'] as Timestamp)
                  .toDate()
                  .toIso8601String(),
              'note': paymentData['note'] ?? '',
              'paymentMethod': paymentData['paymentMethod'] ?? 'cash',
              'referenceNumber': paymentData['referenceNumber'],
            });
          }

          // Get order data
          // ignore: unnecessary_cast
          Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;

          // Create order with updated payment history
          return BuyOrder(
            id: doc.id,
            date: (orderData['date'] as Timestamp).toDate(),
            supplierName: orderData['supplierName'] ?? '',
            supplierAddress: orderData['supplierAddress'] ?? '',
            productId: orderData['productId'] ?? '',
            productName: orderData['productName'] ?? '',
            productCode: orderData['productCode'] ?? '',
            quantity: (orderData['quantity'] as num).toDouble(),
            rate: (orderData['rate'] as num).toDouble(),
            totalAmount: (orderData['totalAmount'] as num).toDouble(),
            status: orderData['status'] ?? 'pending',
            paid: orderData['paid'] ?? false,
            paidAmount: totalPaid, // Use calculated total from transactions
            paymentHistory: paymentHistory,
            createdAt: (orderData['createdAt'] as Timestamp).toDate(),
            createdBy: orderData['createdBy'] ?? '',
          );
        }),
      );
    } catch (e) {
      if (kDebugMode) print('Error loading buy orders with payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
