// File: lib/screens/partial_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sell_order_provider.dart';
import '../models/sell_order_model.dart';
import '../utils/currency_helper.dart';

class PartialPaymentDialog extends StatefulWidget {
  final SellOrder order;
  final String userCurrency;

  const PartialPaymentDialog({
    super.key,
    required this.order,
    required this.userCurrency,
  });

  @override
  _PartialPaymentDialogState createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<PartialPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize with remaining amount
    _amountController.text = widget.order.pendingPaymentAmount.toStringAsFixed(
      2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellOrderProvider = Provider.of<SellOrderProvider>(
      context,
      listen: false,
    );
    final order = widget.order;
    final pendingAmount = order.pendingPaymentAmount;
    final paidPercentage = order.paymentPercentage;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: Color(0xFF1976D2)), // Medium blue
          SizedBox(width: 10),
          Text(
            'Add Payment',
            style: TextStyle(color: Color(0xFF1565C0)),
          ), // Dark blue
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
                color: Color(0xFFE3F2FD), // Light blue background
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Color(0xFFBBDEFB),
                  ), // Light blue border
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: TextStyle(color: Color(0xFF1565C0)),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              order.totalAmount,
                              widget.userCurrency,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0), // Dark blue
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Already Paid:',
                            style: TextStyle(color: Color(0xFF1565C0)),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              order.paymentReceivedAmount,
                              widget.userCurrency,
                            ),
                            style: TextStyle(
                              color: Colors
                                  .green[700], // Keep green for paid amount
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pending:',
                            style: TextStyle(color: Color(0xFF1565C0)),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              pendingAmount,
                              widget.userCurrency,
                            ),
                            style: TextStyle(
                              color:
                                  Colors.orange[700], // Keep orange for pending
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: paidPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green, // Keep green for progress
                        minHeight: 8,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${paidPercentage.toStringAsFixed(1)}% Paid',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1976D2), // Medium blue
                        ),
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
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF1976D2),
                    ), // Medium blue when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
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
                  if (amount > pendingAmount) {
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
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF1976D2),
                    ), // Medium blue when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.payment,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1976D2),
                ), // Medium blue icon
                borderRadius: BorderRadius.circular(8),
                style: TextStyle(color: Color(0xFF1565C0)), // Dark blue text
                initialValue: _paymentMethod,
                items: [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text(
                      'Cash',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text(
                      'Bank Transfer',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'cheque',
                    child: Text(
                      'Cheque',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'card',
                    child: Text(
                      'Card',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'upi',
                    child: Text(
                      'UPI',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(
                      'Other',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
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
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'e.g., Transaction ID, Cheque No.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF1976D2),
                    ), // Medium blue when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.receipt,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
              ),

              SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF1976D2),
                    ), // Medium blue when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.note,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFFE3F2FD)), // Light blue border
      ),
      backgroundColor: Colors.white,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF1976D2)), // Medium blue text
          ),
        ),
        _isProcessing
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF1976D2),
                ), // Medium blue progress
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2), // Medium blue background
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isProcessing = true);

                  try {
                    final amount = double.parse(_amountController.text);

                    // Add partial payment
                    bool success = await sellOrderProvider.addPartialPayment(
                      orderId: order.id,
                      amount: amount,
                      note: _noteController.text,
                    );

                    if (success) {
                      // Record transaction
                      await sellOrderProvider.recordPaymentTransaction(
                        orderId: order.id,
                        amount: amount,
                        paymentMethod: _paymentMethod,
                        note: _noteController.text,
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
                            backgroundColor: Color(0xFF1976D2), // Medium blue
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to record payment'),
                            backgroundColor: Color(
                              0xFF1565C0,
                            ), // Dark blue for error
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Color(
                            0xFF1565C0,
                          ), // Dark blue for error
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isProcessing = false);
                    }
                  }
                },
                child: Text('Record Payment'),
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
