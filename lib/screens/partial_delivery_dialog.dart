// File: lib/screens/partial_delivery_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sell_order_provider.dart';
import '../models/sell_order_model.dart';

class PartialDeliveryDialog extends StatefulWidget {
  final SellOrder order;

  const PartialDeliveryDialog({super.key, required this.order});

  @override
  _PartialDeliveryDialogState createState() => _PartialDeliveryDialogState();
}

class _PartialDeliveryDialogState extends State<PartialDeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  final _trackingController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize with remaining quantity
    _quantityController.text = widget.order.pendingDeliveryQuantity
        .toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final sellOrderProvider = Provider.of<SellOrderProvider>(
      context,
      listen: false,
    );
    final order = widget.order;
    final pendingQuantity = order.pendingDeliveryQuantity;
    final deliveredPercentage = order.deliveryPercentage;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.blue),
          SizedBox(width: 10),
          Text('Add Delivery'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Summary
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Quantity:'),
                          Text(
                            '${order.quantity.toStringAsFixed(2)} ${order.productCode}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Already Delivered:'),
                          Text(
                            '${order.deliveredQuantity.toStringAsFixed(2)} ${order.productCode}',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pending:'),
                          Text(
                            '${pendingQuantity.toStringAsFixed(2)} ${order.productCode}',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: deliveredPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                        minHeight: 8,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${deliveredPercentage.toStringAsFixed(1)}% Delivered',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Delivery Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Delivery Quantity*',
                  hintText: 'Enter quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                  suffixText: order.productCode,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = double.tryParse(value);
                  if (quantity == null) {
                    return 'Please enter valid number';
                  }
                  if (quantity <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  if (quantity > pendingQuantity) {
                    return 'Quantity cannot exceed pending quantity';
                  }
                  return null;
                },
              ),

              SizedBox(height: 15),

              // Tracking Number
              TextFormField(
                controller: _trackingController,
                decoration: InputDecoration(
                  labelText: 'Tracking Number (Optional)',
                  hintText: 'e.g., AWB, Tracking ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
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
                    final quantity = double.parse(_quantityController.text);

                    // Add partial delivery
                    bool success = await sellOrderProvider.addPartialDelivery(
                      orderId: order.id,
                      quantity: quantity,
                      note: _noteController.text,
                    );

                    if (success) {
                      // Record transaction
                      await sellOrderProvider.recordDeliveryTransaction(
                        orderId: order.id,
                        quantity: quantity,
                        note: _noteController.text,
                        trackingNumber: _trackingController.text.isNotEmpty
                            ? _trackingController.text
                            : null,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Delivery of $quantity ${order.productCode} recorded successfully',
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to record delivery'),
                            backgroundColor: Colors.red,
                          ),
                        );
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Record Delivery'),
              ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    _trackingController.dispose();
    super.dispose();
  }
}
