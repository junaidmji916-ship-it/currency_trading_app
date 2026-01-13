// File: lib/models/buy_order_model.dart - UPDATED
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
  String status; // 'pending' or 'completed'
  bool paid;

  // PARTIAL PAYMENT SUPPORT - ADD THESE FIELDS
  double paidAmount; // Track partial payment amount
  double pendingPaymentAmount; // Calculate pending amount
  DateTime? paymentDate; // Track when payment was made

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
    required this.createdAt,
    required this.createdBy,
  }) : pendingPaymentAmount = totalAmount - paidAmount;

  factory BuyOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Extract partial payment data (with defaults)
    double paidAmount = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;

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
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };

    // Add payment date if it exists
    if (paymentDate != null) {
      data['paymentDate'] = Timestamp.fromDate(paymentDate!);
    }

    return data;
  }

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';

  // Check if fully paid
  bool get isFullyPaid => paidAmount >= totalAmount;

  // Get payment percentage
  double get paymentPercentage =>
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

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
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
