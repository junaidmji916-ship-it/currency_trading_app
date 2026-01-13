// File: lib/screens/payment_history_buy_dialog.dart
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
  _PaymentHistoryBuyDialogState createState() =>
      _PaymentHistoryBuyDialogState();
}

class _PaymentHistoryBuyDialogState extends State<PaymentHistoryBuyDialog> {
  late Future<List<Map<String, dynamic>>> _paymentHistoryFuture;
  bool _isLoading = true;
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    final buyOrderProvider = Provider.of<BuyOrderProvider>(
      context,
      listen: false,
    );

    try {
      _paymentHistory = await buyOrderProvider.getPaymentHistory(
        widget.order.id,
      );
    } catch (e) {
      print('Error loading payment history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.history, color: Colors.purple),
          SizedBox(width: 10),
          Text('Payment History'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _paymentHistory.isEmpty
            ? Center(child: Text('No payment history found'))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payments:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyHelper.formatAmount(
                          widget.order.paidAmount,
                          widget.userCurrency,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _paymentHistory.length,
                      itemBuilder: (context, index) {
                        final payment = _paymentHistory[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(
                              Icons.payment,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            CurrencyHelper.formatAmount(
                              (payment['amount'] as num).toDouble(),
                              widget.userCurrency,
                            ),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Method: ${payment['paymentMethod'] ?? 'Not specified'}',
                              ),
                              if (payment['referenceNumber'] != null)
                                Text('Ref: ${payment['referenceNumber']}'),
                              if (payment['note'] != null)
                                Text('Note: ${payment['note']}'),
                              Text(
                                'Date: ${_formatDate((payment['date'] as Timestamp).toDate())}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (context) => PartialPaymentBuyDialog(
                                  order: widget.order,
                                  userCurrency: widget.userCurrency,
                                  paymentTransaction:
                                      payment, // Pass the transaction data
                                ),
                              );

                              if (result != null && mounted) {
                                await _loadPaymentHistory();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
