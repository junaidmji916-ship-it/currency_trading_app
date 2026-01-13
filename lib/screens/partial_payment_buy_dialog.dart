// File: lib/screens/partial_payment_buy_dialog.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../models/buy_order_model.dart';
import '../utils/currency_helper.dart';

class PartialPaymentBuyDialog extends StatefulWidget {
  final BuyOrder order;
  final String userCurrency;
  final Map<String, dynamic>? paymentTransaction; // For editing

  const PartialPaymentBuyDialog({
    super.key,
    required this.order,
    required this.userCurrency,
    this.paymentTransaction,
  });

  @override
  _PartialPaymentBuyDialogState createState() =>
      _PartialPaymentBuyDialogState();
}

class _PartialPaymentBuyDialogState extends State<PartialPaymentBuyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isProcessing = false;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.paymentTransaction != null;

    if (_isEditing) {
      // Editing existing payment
      final transaction = widget.paymentTransaction!;
      _amountController.text = (transaction['amount'] as num).toStringAsFixed(
        2,
      );
      _paymentMethod = transaction['paymentMethod'] ?? 'cash';
      _referenceController.text = transaction['referenceNumber'] ?? '';
      _noteController.text = transaction['note'] ?? '';
    } else {
      // New payment
      _amountController.text = widget.order.pendingPaymentAmount
          .toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyOrderProvider = Provider.of<BuyOrderProvider>(
      context,
      listen: false,
    );
    final order = widget.order;
    final pendingAmount = order.pendingPaymentAmount;
    final paidPercentage = order.paymentPercentage;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: _isEditing ? Colors.orange : Colors.green),
          SizedBox(width: 10),
          Text(_isEditing ? 'Edit Payment' : 'Add Payment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount:'),
                          Text(
                            CurrencyHelper.formatAmount(
                              order.totalAmount,
                              widget.userCurrency,
                            ),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Already Paid:'),
                          Text(
                            CurrencyHelper.formatAmount(
                              order.paidAmount,
                              widget.userCurrency,
                            ),
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pending:'),
                          Text(
                            CurrencyHelper.formatAmount(
                              pendingAmount,
                              widget.userCurrency,
                            ),
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: paidPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 8,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${paidPercentage.toStringAsFixed(1)}% Paid',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Payment Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Payment Amount*',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: widget.userCurrency,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (!_isEditing && amount > pendingAmount) {
                    return 'Amount cannot exceed pending amount';
                  }
                  return null;
                },
              ),

              SizedBox(height: 15),

              // Payment Method
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                value: _paymentMethod,
                items: [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Bank Transfer'),
                  ),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),

              SizedBox(height: 15),

              // Reference Number
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: 'Reference Number (Optional)',
                  hintText: 'e.g., Transaction ID, Cheque No.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),

              SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Payment'),
                  content: Text(
                    'Are you sure you want to delete this payment record?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                // Delete the payment transaction
                final transactionId = widget.paymentTransaction!['id'];
                final success = await buyOrderProvider.deletePaymentTransaction(
                  orderId: order.id,
                  transactionId: transactionId,
                );

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, {'deleted': true});
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        _isProcessing
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isProcessing = true);

                  try {
                    final amount = double.parse(_amountController.text);

                    if (_isEditing) {
                      // Update existing payment
                      final transactionId = widget.paymentTransaction!['id'];
                      final success = await buyOrderProvider
                          .updatePaymentTransaction(
                            orderId: order.id,
                            transactionId: transactionId,
                            amount: amount,
                            paymentMethod: _paymentMethod,
                            referenceNumber:
                                _referenceController.text.isNotEmpty
                                ? _referenceController.text
                                : null,
                            note: _noteController.text.isNotEmpty
                                ? _noteController.text
                                : null,
                          );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, {'updated': true});
                      }
                    } else {
                      // Add new payment
                      bool success = await buyOrderProvider.addPartialPayment(
                        orderId: order.id,
                        amount: amount,
                        note: '',
                      );

                      if (success) {
                        // Record transaction
                        await buyOrderProvider.recordPaymentTransaction(
                          orderId: order.id,
                          amount: amount,
                          paymentMethod: _paymentMethod,
                          note: _noteController.text.isNotEmpty
                              ? _noteController.text
                              : null,
                          referenceNumber: _referenceController.text.isNotEmpty
                              ? _referenceController.text
                              : null,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Payment of ${CurrencyHelper.formatAmount(amount, widget.userCurrency)} recorded successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isProcessing = false);
                    }
                  }
                },
                child: Text(_isEditing ? 'Update Payment' : 'Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.orange : Colors.green,
                ),
              ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
