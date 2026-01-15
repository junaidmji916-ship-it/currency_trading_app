// File: lib/screens/payment_history_buy_dialog.dart - BLUE THEME
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../models/buy_order_model.dart';
import '../utils/currency_helper.dart';
import 'partial_payment_buy_dialog.dart';

class PaymentHistoryBuyDialog extends StatefulWidget {
  final BuyOrder order;
  final String userCurrency;

  const PaymentHistoryBuyDialog({
    super.key,
    required this.order,
    required this.userCurrency,
  });

  @override
  State<PaymentHistoryBuyDialog> createState() =>
      _PaymentHistoryBuyDialogState();
}

class _PaymentHistoryBuyDialogState extends State<PaymentHistoryBuyDialog> {
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final provider = Provider.of<BuyOrderProvider>(context, listen: false);
      final history = await provider.getPaymentHistory(widget.order.id);

      if (mounted) {
        setState(() {
          _paymentHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1565C0), // Dark blue
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF1565C0),
                  ), // Blue close icon
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Info Card
            Card(
              color: const Color(0xFFE3F2FD), // Light blue background
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: Color(0xFFBBDEFB), // Light blue border
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.supplierName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${CurrencyHelper.formatAmount(widget.order.totalAmount, widget.userCurrency)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.order.isFullyPaid
                            ? const Color(0xFFE8F5E9) // Light green
                            : const Color(0xFFFFF3E0), // Light orange
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.order.isFullyPaid
                              ? const Color(0xFFC8E6C9) // Green border
                              : const Color(0xFFFFE0B2), // Orange border
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.order.isFullyPaid
                            ? 'Fully Paid'
                            : 'Partially Paid',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: widget.order.isFullyPaid
                              ? const Color(0xFF388E3C) // Green text
                              : const Color(0xFFF57C00), // Orange text
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Payment History List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1565C0),
                    ),
                  ),
                ),
              )
            else if (_paymentHistory.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    children: _paymentHistory.map((payment) {
                      return _buildPaymentItem(payment, context);
                    }).toList(),
                  ),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No payment history available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment, BuildContext context) {
    final buyOrderProvider = Provider.of<BuyOrderProvider>(
      context,
      listen: false,
    );
    final amount = payment['amount'] ?? 0.0;
    final date = payment['date'] != null
        ? (payment['date'] as Timestamp).toDate()
        : DateTime.now();
    final note = payment['note'] ?? '';
    final paymentMethod = payment['paymentMethod'] ?? 'cash';
    final referenceNumber = payment['referenceNumber'];
    final transactionId = payment['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFF0F8FF), // Very light blue
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: Color(0xFFBBDEFB), // Light blue border
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with amount and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyHelper.formatAmount(amount, widget.userCurrency),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF388E3C), // Green for amounts
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getPaymentMethodColor(
                          paymentMethod,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getPaymentMethodColor(
                            paymentMethod,
                          ).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        paymentMethod.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getPaymentMethodColor(paymentMethod),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: const Color(0xFF1976D2), // Blue edit icon
                      onPressed: () => _showEditPaymentDialog(
                        context,
                        payment,
                        buyOrderProvider,
                      ),
                      tooltip: 'Edit Payment',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: const Color(0xFFD32F2F), // Red delete icon
                      onPressed: () => _confirmDeletePayment(
                        context,
                        transactionId,
                        buyOrderProvider,
                      ),
                      tooltip: 'Delete Payment',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            // Reference number
            if (referenceNumber != null && referenceNumber.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.receipt, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ref: $referenceNumber',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Note
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Note: $note',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2), // Blue text for notes
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xFF388E3C); // Green
      case 'bank':
        return const Color(0xFF1976D2); // Blue
      case 'card':
        return const Color(0xFF7B1FA2); // Purple
      default:
        return const Color(0xFF1976D2); // Default blue
    }
  }

  Future<void> _showEditPaymentDialog(
    BuildContext context,
    Map<String, dynamic> payment,
    BuyOrderProvider provider,
  ) async {
    try {
      final result = await showDialog(
        context: context,
        builder: (context) => PartialPaymentBuyDialog(
          order: widget.order,
          userCurrency: widget.userCurrency,
          paymentTransaction: payment,
          note: payment['note'] ?? '',
        ),
      );

      if (!mounted) return;

      final shouldRefresh =
          result == true ||
          result?['updated'] == true ||
          result?['deleted'] == true;

      if (shouldRefresh) {
        await _loadPaymentHistory();

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeletePayment(
    BuildContext context,
    String transactionId,
    BuyOrderProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Payment',
          style: TextStyle(color: Color(0xFF1565C0)),
        ),
        content: const Text(
          'Are you sure you want to delete this payment?',
          style: TextStyle(color: Color(0xFF1976D2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deletePaymentTransaction(
        orderId: widget.order.id,
        transactionId: transactionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Payment deleted successfully'
                  : 'Failed to delete payment',
            ),
            backgroundColor: success
                ? const Color(0xFF388E3C) // Green
                : const Color(0xFFD32F2F), // Red
          ),
        );
        if (success) {
          await _loadPaymentHistory();
        }
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
