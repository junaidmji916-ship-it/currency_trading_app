// File: lib/models/buy_order_model.dart - FIXED
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyOrder {
  String id;
  DateTime date;
  String supplierName;
  String supplierAddress;
  String productId;
  String productName;
  String productCode;
  double quantity;
  double rate;
  double totalAmount;
  String status;
  bool paid;
  double paidAmount;
  double pendingPaymentAmount;
  DateTime? paymentDate;

  // CHANGE THIS: Add paymentHistory field
  List<Map<String, dynamic>> paymentHistory;

  DateTime createdAt;
  String createdBy;

  BuyOrder({
    required this.id,
    required this.date,
    required this.supplierName,
    required this.supplierAddress,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.rate,
    required this.totalAmount,
    required this.status,
    required this.paid,
    this.paidAmount = 0.0,
    this.paymentDate,
    this.paymentHistory = const [], // Initialize as empty list
    required this.createdAt,
    required this.createdBy,
  }) : pendingPaymentAmount = totalAmount - paidAmount;

  factory BuyOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    double paidAmount = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;

    // REMOVE THIS: get paymentHistory => null;
    // AND ADD: Initialize paymentHistory from data if exists
    List<Map<String, dynamic>> paymentHistory = [];
    if (data['paymentHistory'] != null && data['paymentHistory'] is List) {
      try {
        paymentHistory = List<Map<String, dynamic>>.from(
          data['paymentHistory'],
        );
      } catch (e) {
        paymentHistory = [];
      }
    }

    return BuyOrder(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      supplierName: data['supplierName'] ?? '',
      supplierAddress: data['supplierAddress'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productCode: data['productCode'] ?? '',
      quantity: (data['quantity'] as num).toDouble(),
      rate: (data['rate'] as num).toDouble(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      status: data['status'] ?? 'pending',
      paid: data['paid'] ?? false,
      paidAmount: paidAmount,
      paymentDate: data['paymentDate'] != null
          ? (data['paymentDate'] as Timestamp).toDate()
          : null,
      paymentHistory: paymentHistory, // Add this
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> data = {
      'date': Timestamp.fromDate(date),
      'supplierName': supplierName,
      'supplierAddress': supplierAddress,
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'quantity': quantity,
      'rate': rate,
      'totalAmount': totalAmount,
      'status': status,
      'paid': paid,
      'paidAmount': paidAmount,
      'paymentHistory': paymentHistory, // Add this
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };

    if (paymentDate != null) {
      data['paymentDate'] = Timestamp.fromDate(paymentDate!);
    }

    return data;
  }

  // Helper methods - KEEP THESE
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFullyPaid => paidAmount >= totalAmount;
  double get paymentPercentage =>
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

  // REMOVE THIS: get paymentHistory => null;

  BuyOrder copyWith({
    String? id,
    DateTime? date,
    String? supplierName,
    String? supplierAddress,
    String? productId,
    String? productName,
    String? productCode,
    double? quantity,
    double? rate,
    double? totalAmount,
    String? status,
    bool? paid,
    double? paidAmount,
    DateTime? paymentDate,
    List<Map<String, dynamic>>? paymentHistory, // Add this
    DateTime? createdAt,
    String? createdBy,
  }) {
    return BuyOrder(
      id: id ?? this.id,
      date: date ?? this.date,
      supplierName: supplierName ?? this.supplierName,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paid: paid ?? this.paid,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentHistory: paymentHistory ?? this.paymentHistory, // Add this
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
