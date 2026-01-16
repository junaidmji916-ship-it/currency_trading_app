// File: lib/screens/partial_payment_buy_dialog.dart - BLUE THEME
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../models/buy_order_model.dart';
import '../utils/currency_helper.dart';

class PartialPaymentBuyDialog extends StatefulWidget {
  final BuyOrder order;
  final String userCurrency;
  final Map<String, dynamic>? paymentTransaction; // For editing
  final String? note;

  const PartialPaymentBuyDialog({
    super.key,
    required this.order,
    required this.userCurrency,
    this.paymentTransaction,
    this.note,
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
      _noteController.text = widget.note ?? '';
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            Icons.payment,
            color: _isEditing
                ? const Color(0xFFF57C00) // Orange for editing
                : const Color(0xFF388E3C), // Green for new payment
          ),
          const SizedBox(width: 10),
          Text(
            _isEditing ? 'Edit Payment' : 'Add Payment',
            style: const TextStyle(
              color: Color(0xFF1565C0), // Dark blue
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary Card
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(color: Color(0xFF1976D2)),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              order.totalAmount,
                              widget.userCurrency,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Already Paid:',
                            style: TextStyle(color: Color(0xFF1976D2)),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              order.paidAmount,
                              widget.userCurrency,
                            ),
                            style: const TextStyle(
                              color: Color(0xFF388E3C), // Green
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending:',
                            style: TextStyle(color: Color(0xFF1976D2)),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              pendingAmount,
                              widget.userCurrency,
                            ),
                            style: const TextStyle(
                              color: Color(0xFFF57C00), // Orange
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: paidPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: paidPercentage == 100
                            ? const Color(0xFF388E3C) // Green for fully paid
                            : const Color(0xFF1976D2), // Blue for partial
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${paidPercentage.toStringAsFixed(1)}% Paid',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Payment Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Payment Amount*',
                  labelStyle: const TextStyle(color: Color(0xFF1976D2)),
                  hintText: 'Enter amount',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1565C0)),
                  ),
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: Color(0xFF1976D2),
                  ),
                  suffixText: widget.userCurrency,
                  suffixStyle: const TextStyle(color: Color(0xFF1976D2)),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                style: const TextStyle(color: Color(0xFF0D47A1)),
              ),

              const SizedBox(height: 15),

              // Payment Method
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  labelStyle: TextStyle(color: Color(0xFF1976D2)),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1565C0)),
                  ),
                  prefixIcon: Icon(Icons.payment, color: Color(0xFF1976D2)),
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF0D47A1)),
                initialValue: _paymentMethod,
                items: [
                  DropdownMenuItem(value: 'cash', child: const Text('Cash')),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: const Text('Bank Transfer'),
                  ),
                  DropdownMenuItem(
                    value: 'cheque',
                    child: const Text('Cheque'),
                  ),
                  DropdownMenuItem(value: 'card', child: const Text('Card')),
                  DropdownMenuItem(value: 'upi', child: const Text('UPI')),
                  DropdownMenuItem(value: 'other', child: const Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              // Reference Number
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (Optional)',
                  labelStyle: TextStyle(color: Color(0xFF1976D2)),
                  hintText: 'e.g., Transaction ID, Cheque No.',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1565C0)),
                  ),
                  prefixIcon: Icon(Icons.receipt, color: Color(0xFF1976D2)),
                ),
                style: const TextStyle(color: Color(0xFF0D47A1)),
              ),

              const SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  labelStyle: TextStyle(color: Color(0xFF1976D2)),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1565C0)),
                  ),
                  prefixIcon: Icon(Icons.note, color: Color(0xFF1976D2)),
                ),
                maxLines: 2,
                style: const TextStyle(color: Color(0xFF0D47A1)),
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
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Delete Payment',
                    style: TextStyle(color: Color(0xFF1565C0)),
                  ),
                  content: const Text(
                    'Are you sure you want to delete this payment record?',
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

              if (confirmed == true && context.mounted) {
                final transactionId = widget.paymentTransaction!['id'];
                final success = await buyOrderProvider.deletePaymentTransaction(
                  orderId: order.id,
                  transactionId: transactionId,
                );

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Payment deleted successfully'),
                      backgroundColor: const Color(0xFF388E3C),
                    ),
                  );
                  Navigator.pop(context, {'deleted': true});
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF1976D2)),
          ),
        ),
        _isProcessing
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              )
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
                            content: const Text('Payment updated successfully'),
                            backgroundColor: const Color(0xFF388E3C),
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
                              backgroundColor: const Color(0xFF388E3C),
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
                          backgroundColor: const Color(0xFFD32F2F),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isProcessing = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing
                      ? const Color(0xFFF57C00) // Orange for edit
                      : const Color(0xFF388E3C), // Green for new payment
                  foregroundColor: Colors.white,
                ),
                child: Text(_isEditing ? 'Update Payment' : 'Record Payment'),
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
