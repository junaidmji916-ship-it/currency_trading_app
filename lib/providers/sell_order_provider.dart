// File: lib/providers/sell_order_provider.dart - CORRECTED
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sell_order_model.dart';
import '../services/firebase_service.dart';

class SellOrderProvider with ChangeNotifier {
  List<SellOrder> _sellOrders = [];
  bool _isLoading = false;

  List<SellOrder> get sellOrders => _sellOrders;
  bool get isLoading => _isLoading;

  // Getters for dashboard stats
  int get totalOrders => _sellOrders.length;
  int get pendingOrders => _sellOrders.where((order) => order.isPending).length;
  int get completedOrders =>
      _sellOrders.where((order) => order.isCompleted).length;

  // Calculate total sales (from payments received)
  double get totalSales {
    return _sellOrders
        .where((order) => order.isCompleted && order.paymentReceived)
        .fold(0.0, (sum, order) => sum + order.paymentReceivedAmount);
  }

  SellOrderProvider() {
    loadSellOrders();
  }

  Future<void> loadSellOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('sell_orders')
          .orderBy('date', descending: true)
          .get();

      _sellOrders = snapshot.docs
          .map((doc) => SellOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading sell orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSellOrder({
    required DateTime date,
    required String customerName,
    required String customerAddress,
    required String productId,
    required String productName,
    required String productCode,
    required double quantity,
    required double rate,
    required String createdBy,
  }) async {
    try {
      final totalAmount = quantity * rate;

      await FirebaseService.firestore.collection('sell_orders').add({
        'date': Timestamp.fromDate(date),
        'customerName': customerName.trim(),
        'customerAddress': customerAddress.trim(),
        'productId': productId,
        'productName': productName,
        'productCode': productCode,
        'quantity': quantity,
        'rate': rate,
        'totalAmount': totalAmount,
        'status': 'pending',
        'paymentReceived': false,
        'paymentReceivedAmount': 0.0,
        'delivered': false,
        'deliveredQuantity': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding sell order: $e');
      return false;
    }
  }

  // NEW: Add partial payment
  Future<bool> addPartialPayment({
    required String orderId,
    required double amount,
    String? note,
  }) async {
    try {
      final order = _sellOrders.firstWhere((order) => order.id == orderId);
      final newPaymentAmount = order.paymentReceivedAmount + amount;
      final isFullyPaid = newPaymentAmount >= order.totalAmount;

      Map<String, dynamic> updates = {
        'paymentReceivedAmount': newPaymentAmount,
        'paymentReceivedDate': FieldValue.serverTimestamp(),
      };

      // If fully paid, update status
      if (isFullyPaid) {
        updates['paymentReceived'] = true;

        // Check if also fully delivered to mark as completed
        if (order.isFullyDelivered) {
          updates['status'] = 'completed';
        }
      }

      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .update(updates);

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding partial payment: $e');
      return false;
    }
  }

  // NEW: Add partial delivery
  Future<bool> addPartialDelivery({
    required String orderId,
    required double quantity,
    String? note,
  }) async {
    try {
      final order = _sellOrders.firstWhere((order) => order.id == orderId);
      final newDeliveredQuantity = order.deliveredQuantity + quantity;
      final isFullyDelivered = newDeliveredQuantity >= order.quantity;

      Map<String, dynamic> updates = {
        'deliveredQuantity': newDeliveredQuantity,
        'deliveredDate': FieldValue.serverTimestamp(),
      };

      // If fully delivered, update status
      if (isFullyDelivered) {
        updates['delivered'] = true;

        // Check if also fully paid to mark as completed
        if (order.isFullyPaid) {
          updates['status'] = 'completed';
        }
      }

      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .update(updates);

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding partial delivery: $e');
      return false;
    }
  }

  // Updated: Update sell order status (for full payments/deliveries)
  Future<bool> updateSellOrderStatus({
    required String orderId,
    double? paymentAmount, // NEW: Optional payment amount
    double? deliveryQuantity, // NEW: Optional delivery quantity
    bool? paymentReceived,
    bool? delivered,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (paymentReceived != null && paymentAmount != null) {
        updates['paymentReceived'] = paymentReceived;
        updates['paymentReceivedAmount'] = paymentAmount;
        updates['paymentReceivedDate'] = FieldValue.serverTimestamp();
      }

      if (delivered != null && deliveryQuantity != null) {
        updates['delivered'] = delivered;
        updates['deliveredQuantity'] = deliveryQuantity;
        updates['deliveredDate'] = FieldValue.serverTimestamp();
      }

      // CORRECTED: If BOTH payment received AND delivered are true AND amounts match, mark as completed
      final order = _sellOrders.firstWhere((order) => order.id == orderId);
      bool newPaymentReceived = paymentReceived ?? order.paymentReceived;
      double newPaymentAmount = paymentAmount ?? order.paymentReceivedAmount;
      bool newDelivered = delivered ?? order.delivered;
      double newDeliveryQuantity = deliveryQuantity ?? order.deliveredQuantity;

      if (newPaymentReceived &&
          newPaymentAmount >= order.totalAmount &&
          newDelivered &&
          newDeliveryQuantity >= order.quantity) {
        updates['status'] = 'completed';
      } else {
        updates['status'] = 'pending';
      }

      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .update(updates);

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating sell order: $e');
      return false;
    }
  }

  Future<bool> deleteSellOrder(String orderId) async {
    try {
      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .delete();

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting sell order: $e');
      return false;
    }
  }

  // Filter methods for reports
  List<SellOrder> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _sellOrders.where((order) {
      return order.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          order.date.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
  }

  List<SellOrder> getPendingOrders() {
    return _sellOrders.where((order) => order.isPending).toList();
  }

  List<SellOrder> getCompletedOrders() {
    return _sellOrders.where((order) => order.isCompleted).toList();
  }

  // Profit calculation (will be implemented after buy orders)
  double calculateProfit() {
    // TODO: Implement profit calculation after buy orders are added
    // Profit = Total Sales - Total Cost (from buy orders)
    return totalSales; // Placeholder
  }

  // Add these methods to SellOrderProvider class
  Future<bool> updateSellOrder({
    required String orderId,
    required DateTime date,
    required String customerName,
    required String customerAddress,
    required String productId,
    required String productName,
    required String productCode,
    required double quantity,
    required double rate,
  }) async {
    try {
      final totalAmount = quantity * rate;

      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .update({
            'date': Timestamp.fromDate(date),
            'customerName': customerName.trim(),
            'customerAddress': customerAddress.trim(),
            'productId': productId,
            'productName': productName,
            'productCode': productCode,
            'quantity': quantity,
            'rate': rate,
            'totalAmount': totalAmount,
          });

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating sell order: $e');
      return false;
    }
  }

  // Updated: Undo payment (now supports partial undo)
  Future<bool> undoPayment(String orderId, {double? amount}) async {
    try {
      final order = _sellOrders.firstWhere((order) => order.id == orderId);
      double newPaymentAmount = order.paymentReceivedAmount;

      if (amount != null) {
        // Partial undo
        newPaymentAmount = (order.paymentReceivedAmount - amount).clamp(
          0.0,
          order.totalAmount,
        );
      } else {
        // Full undo
        newPaymentAmount = 0.0;
      }

      Map<String, dynamic> updates = {
        'paymentReceivedAmount': newPaymentAmount,
        'paymentReceived': newPaymentAmount >= order.totalAmount,
      };

      // If payment is no longer full, reset completion status
      if (newPaymentAmount < order.totalAmount) {
        updates['status'] = 'pending';
      }

      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .update(updates);

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error undoing payment: $e');
      return false;
    }
  }

  // Updated: Undo delivery (now supports partial undo)
  Future<bool> undoDelivery(String orderId, {double? quantity}) async {
    try {
      final order = _sellOrders.firstWhere((order) => order.id == orderId);
      double newDeliveredQuantity = order.deliveredQuantity;

      if (quantity != null) {
        // Partial undo
        newDeliveredQuantity = (order.deliveredQuantity - quantity).clamp(
          0.0,
          order.quantity,
        );
      } else {
        // Full undo
        newDeliveredQuantity = 0.0;
      }

      Map<String, dynamic> updates = {
        'deliveredQuantity': newDeliveredQuantity,
        'delivered': newDeliveredQuantity >= order.quantity,
      };

      // If delivery is no longer full, reset completion status
      if (newDeliveredQuantity < order.quantity) {
        updates['status'] = 'pending';
      }

      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .update(updates);

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error undoing delivery: $e');
      return false;
    }
  }

  // NEW: Record payment transaction in subcollection
  Future<bool> recordPaymentTransaction({
    required String orderId,
    required double amount,
    required String paymentMethod,
    String? note,
    String? referenceNumber,
  }) async {
    try {
      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .add({
            'amount': amount,
            'paymentMethod': paymentMethod,
            'note': note,
            'referenceNumber': referenceNumber,
            'date': FieldValue.serverTimestamp(),
            'createdBy': 'system', // You can get actual user ID
          });

      return true;
    } catch (e) {
      if (kDebugMode) print('Error recording payment transaction: $e');
      return false;
    }
  }

  // NEW: Record delivery transaction in subcollection
  Future<bool> recordDeliveryTransaction({
    required String orderId,
    required double quantity,
    String? note,
    String? trackingNumber,
  }) async {
    try {
      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('delivery_transactions')
          .add({
            'quantity': quantity,
            'note': note,
            'trackingNumber': trackingNumber,
            'date': FieldValue.serverTimestamp(),
            'createdBy': 'system', // You can get actual user ID
          });

      return true;
    } catch (e) {
      if (kDebugMode) print('Error recording delivery transaction: $e');
      return false;
    }
  }

  // ====== PAYMENT & DELIVERY TRANSACTION MANAGEMENT ======

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(String orderId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('sell_orders')
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

  // Get delivery history
  Future<List<Map<String, dynamic>>> getDeliveryHistory(String orderId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('delivery_transactions')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID for editing/deleting
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting delivery history: $e');
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
          .collection('sell_orders')
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
          .collection('sell_orders')
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

      // Update order's payment received amount
      if (amountDifference != 0) {
        final orderDoc = await FirebaseService.firestore
            .collection('sell_orders')
            .doc(orderId)
            .get();

        if (orderDoc.exists) {
          final currentAmount =
              (orderDoc.data()!['paymentReceivedAmount'] as num).toDouble();
          final newAmount = currentAmount + amountDifference;
          final totalAmount = (orderDoc.data()!['totalAmount'] as num)
              .toDouble();

          await FirebaseService.firestore
              .collection('sell_orders')
              .doc(orderId)
              .update({
                'paymentReceivedAmount': newAmount,
                'paymentReceived': newAmount >= totalAmount,
                'status': newAmount >= totalAmount ? 'completed' : 'pending',
              });
        }
      }

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating payment transaction: $e');
      return false;
    }
  }

  // Update delivery transaction
  Future<bool> updateDeliveryTransaction({
    required String orderId,
    required String transactionId,
    required double quantity,
    String? trackingNumber,
    String? note,
  }) async {
    try {
      // Get old quantity to adjust order total
      final oldTransaction = await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('delivery_transactions')
          .doc(transactionId)
          .get();

      final oldQuantity = oldTransaction.exists
          ? (oldTransaction.data()!['quantity'] as num).toDouble()
          : 0.0;

      final quantityDifference = quantity - oldQuantity;

      // Update transaction
      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('delivery_transactions')
          .doc(transactionId)
          .update({
            'quantity': quantity,
            'trackingNumber': trackingNumber,
            'note': note,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update order's delivered quantity
      if (quantityDifference != 0) {
        final orderDoc = await FirebaseService.firestore
            .collection('sell_orders')
            .doc(orderId)
            .get();

        if (orderDoc.exists) {
          final currentQuantity = (orderDoc.data()!['deliveredQuantity'] as num)
              .toDouble();
          final newQuantity = currentQuantity + quantityDifference;
          final totalQuantity = (orderDoc.data()!['quantity'] as num)
              .toDouble();

          await FirebaseService.firestore
              .collection('sell_orders')
              .doc(orderId)
              .update({
                'deliveredQuantity': newQuantity,
                'delivered': newQuantity >= totalQuantity,
                'status': newQuantity >= totalQuantity
                    ? 'completed'
                    : 'pending',
              });
        }
      }

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating delivery transaction: $e');
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
          .collection('sell_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) return false;

      final amount = (transactionDoc.data()!['amount'] as num).toDouble();

      // Delete the transaction
      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('payment_transactions')
          .doc(transactionId)
          .delete();

      // Update the order's payment received amount
      final orderDoc = await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final currentAmount = (orderDoc.data()!['paymentReceivedAmount'] as num)
            .toDouble();
        final newAmount = currentAmount - amount;
        final totalAmount = (orderDoc.data()!['totalAmount'] as num).toDouble();

        await FirebaseService.firestore
            .collection('sell_orders')
            .doc(orderId)
            .update({
              'paymentReceivedAmount': newAmount,
              'paymentReceived': newAmount >= totalAmount,
              'status': newAmount >= totalAmount ? 'completed' : 'pending',
            });
      }

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting payment transaction: $e');
      return false;
    }
  }

  // Delete delivery transaction
  Future<bool> deleteDeliveryTransaction({
    required String orderId,
    required String transactionId,
  }) async {
    try {
      // Get the transaction to know the quantity
      final transactionDoc = await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('delivery_transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) return false;

      final quantity = (transactionDoc.data()!['quantity'] as num).toDouble();

      // Delete the transaction
      await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .collection('delivery_transactions')
          .doc(transactionId)
          .delete();

      // Update the order's delivered quantity
      final orderDoc = await FirebaseService.firestore
          .collection('sell_orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final currentQuantity = (orderDoc.data()!['deliveredQuantity'] as num)
            .toDouble();
        final newQuantity = currentQuantity - quantity;
        final totalQuantity = (orderDoc.data()!['quantity'] as num).toDouble();

        await FirebaseService.firestore
            .collection('sell_orders')
            .doc(orderId)
            .update({
              'deliveredQuantity': newQuantity,
              'delivered': newQuantity >= totalQuantity,
              'status': newQuantity >= totalQuantity ? 'completed' : 'pending',
            });
      }

      await loadSellOrders(); // Refresh list
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting delivery transaction: $e');
      return false;
    }
  }
}
