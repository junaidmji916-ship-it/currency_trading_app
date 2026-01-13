// File: lib/models/sell_order_model.dart - UPDATED
import 'package:cloud_firestore/cloud_firestore.dart';

class SellOrder {
  String id;
  DateTime date;
  String customerName;
  String customerAddress;
  String productId;
  String productName;
  String productCode;
  double quantity;
  double rate;
  double totalAmount;
  String status; // 'pending' or 'completed'

  // PARTIAL PAYMENT SUPPORT
  bool paymentReceived;
  double paymentReceivedAmount; // NEW: Track partial payment amount
  double pendingPaymentAmount; // NEW: Calculate pending amount
  DateTime? paymentReceivedDate; // NEW: Track when payment was made

  // PARTIAL DELIVERY SUPPORT
  bool delivered;
  double deliveredQuantity; // NEW: Track delivered quantity
  double pendingDeliveryQuantity; // NEW: Calculate pending delivery
  DateTime? deliveredDate; // NEW: Track when delivery was made

  DateTime createdAt;
  String createdBy;

  SellOrder({
    required this.id,
    required this.date,
    required this.customerName,
    required this.customerAddress,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.rate,
    required this.totalAmount,
    required this.status,

    // Initialize with partial support
    required this.paymentReceived,
    this.paymentReceivedAmount = 0.0,
    required this.delivered,
    this.deliveredQuantity = 0.0,
    DateTime? paymentReceivedDate,
    DateTime? deliveredDate,

    required this.createdAt,
    required this.createdBy,
  }) : paymentReceivedDate = paymentReceivedDate,
       deliveredDate = deliveredDate,
       pendingPaymentAmount = totalAmount - paymentReceivedAmount,
       pendingDeliveryQuantity = quantity - deliveredQuantity;

  factory SellOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Extract partial payment data (with defaults)
    double paymentReceivedAmount =
        (data['paymentReceivedAmount'] as num?)?.toDouble() ?? 0.0;
    double deliveredQuantity =
        (data['deliveredQuantity'] as num?)?.toDouble() ?? 0.0;

    // Calculate derived values
    double totalAmount = (data['totalAmount'] as num).toDouble();
    double quantity = (data['quantity'] as num).toDouble();

    return SellOrder(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      customerName: data['customerName'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productCode: data['productCode'] ?? '',
      quantity: quantity,
      rate: (data['rate'] as num).toDouble(),
      totalAmount: totalAmount,
      status: data['status'] ?? 'pending',
      paymentReceived: data['paymentReceived'] ?? false,
      paymentReceivedAmount: paymentReceivedAmount,
      delivered: data['delivered'] ?? false,
      deliveredQuantity: deliveredQuantity,
      paymentReceivedDate: data['paymentReceivedDate'] != null
          ? (data['paymentReceivedDate'] as Timestamp).toDate()
          : null,
      deliveredDate: data['deliveredDate'] != null
          ? (data['deliveredDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> data = {
      'date': Timestamp.fromDate(date),
      'customerName': customerName,
      'customerAddress': customerAddress,
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'quantity': quantity,
      'rate': rate,
      'totalAmount': totalAmount,
      'status': status,
      'paymentReceived': paymentReceived,
      'paymentReceivedAmount': paymentReceivedAmount,
      'delivered': delivered,
      'deliveredQuantity': deliveredQuantity,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };

    // Add dates if they exist
    if (paymentReceivedDate != null) {
      data['paymentReceivedDate'] = Timestamp.fromDate(paymentReceivedDate!);
    }

    if (deliveredDate != null) {
      data['deliveredDate'] = Timestamp.fromDate(deliveredDate!);
    }

    return data;
  }

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';

  // Check if fully paid
  bool get isFullyPaid => paymentReceivedAmount >= totalAmount;

  // Check if fully delivered
  bool get isFullyDelivered => deliveredQuantity >= quantity;

  // Get payment percentage
  double get paymentPercentage =>
      totalAmount > 0 ? (paymentReceivedAmount / totalAmount) * 100 : 0;

  // Get delivery percentage
  double get deliveryPercentage =>
      quantity > 0 ? (deliveredQuantity / quantity) * 100 : 0;

  SellOrder copyWith({
    String? id,
    DateTime? date,
    String? customerName,
    String? customerAddress,
    String? productId,
    String? productName,
    String? productCode,
    double? quantity,
    double? rate,
    double? totalAmount,
    String? status,
    bool? paymentReceived,
    double? paymentReceivedAmount,
    bool? delivered,
    double? deliveredQuantity,
    DateTime? paymentReceivedDate,
    DateTime? deliveredDate,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return SellOrder(
      id: id ?? this.id,
      date: date ?? this.date,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentReceived: paymentReceived ?? this.paymentReceived,
      paymentReceivedAmount:
          paymentReceivedAmount ?? this.paymentReceivedAmount,
      delivered: delivered ?? this.delivered,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      paymentReceivedDate: paymentReceivedDate ?? this.paymentReceivedDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
