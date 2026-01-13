// File: lib/screens/sell_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sell_order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/sell_order_model.dart';
import '../utils/currency_helper.dart';
import 'create_sell_order_screen.dart';
import 'edit_sell_order_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellOrdersScreen extends StatefulWidget {
  const SellOrdersScreen({super.key});

  @override
  State<SellOrdersScreen> createState() => _SellOrdersScreenState();
}

class _SellOrdersScreenState extends State<SellOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sell Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateSellOrderScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<SellOrderProvider, AuthProvider>(
        builder: (context, sellOrderProvider, authProvider, child) {
          final userCurrency =
              authProvider.userData?['transactionCurrency'] ?? 'USD';

          if (sellOrderProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (sellOrderProvider.sellOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No sell orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap + to create your first sell order',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: sellOrderProvider.sellOrders.length,
            itemBuilder: (context, index) {
              SellOrder order = sellOrderProvider.sellOrders[index];
              final productCurrency = order.productCode;
              return SellOrderCard(
                order: order,
                userCurrency: userCurrency,
                productCurrency: productCurrency,
              );
            },
          );
        },
      ),
    );
  }
}

// File: lib/screens/sell_orders_screen.dart - UPDATED SellOrderCard widget
// Replace the existing SellOrderCard with this updated version:

class SellOrderCard extends StatefulWidget {
  final SellOrder order;
  final String userCurrency;
  final String productCurrency;

  const SellOrderCard({
    super.key,
    required this.order,
    required this.userCurrency,
    required this.productCurrency,
  });

  @override
  State<SellOrderCard> createState() => _SellOrderCardState();
}

class _SellOrderCardState extends State<SellOrderCard> {
  bool _isProcessing = false;
  bool _showReciprocalRate = false;
  bool _showPaymentDetails = false;
  bool _showDeliveryDetails = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final userCurrency = widget.userCurrency;
    final productCurrency = widget.productCurrency;
    final sellOrderProvider = Provider.of<SellOrderProvider>(
      context,
      listen: false,
    );
    final reciprocalRate = CurrencyHelper.getReciprocalRate(order.rate);

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: order.isCompleted
                      ? Colors.green[100]
                      : Colors.orange[100],
                  child: Icon(
                    order.isCompleted ? Icons.check_circle : Icons.pending,
                    color: order.isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${order.productName} (${order.productCode})',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        order.isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: order.isCompleted
                          ? Colors.green
                          : Colors.orange,
                    ),
                    SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditSellOrderScreen(order: order),
                            ),
                          );
                        } else if (value == 'delete') {
                          await _showDeleteDialog(
                            context,
                            order,
                            sellOrderProvider,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 15),

            // Order details with conversion rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DetailItem(label: 'Date', value: _formatDate(order.date)),
                DetailItem(
                  label: 'Amount',
                  value:
                      '${order.quantity.toStringAsFixed(2)} $productCurrency',
                ),
                // Toggle between direct and reciprocal rate
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showReciprocalRate = !_showReciprocalRate;
                    });
                  },
                  child: DetailItem(
                    label: 'Rate',
                    value: _showReciprocalRate
                        ? '1 $userCurrency = ${reciprocalRate.toStringAsFixed(2)} $productCurrency'
                        : '1 $productCurrency = ${order.rate.toStringAsFixed(4)} $userCurrency',
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DetailItem(
                  label: 'Total',
                  value: CurrencyHelper.formatAmount(
                    order.totalAmount,
                    userCurrency,
                  ),
                  isTotal: true,
                ),
                // Show conversion info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _showReciprocalRate
                          ? '1 $productCurrency = ${order.rate.toStringAsFixed(4)} $userCurrency'
                          : '1 $userCurrency = ${reciprocalRate.toStringAsFixed(2)} $productCurrency',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap rate to toggle',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            // Payment Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${order.paymentReceivedAmount.toStringAsFixed(2)} / ${order.totalAmount.toStringAsFixed(2)} $userCurrency',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: order.paymentPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  color: order.isFullyPaid ? Colors.green : Colors.orange,
                  minHeight: 6,
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.paymentPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPaymentDetails = !_showPaymentDetails;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            _showPaymentDetails ? 'Hide' : 'Details',
                            style: TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                          Icon(
                            _showPaymentDetails
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Payment Details (collapsible)
                if (_showPaymentDetails)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Paid:', style: TextStyle(fontSize: 12)),
                              Text(
                                CurrencyHelper.formatAmount(
                                  order.paymentReceivedAmount,
                                  userCurrency,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pending:', style: TextStyle(fontSize: 12)),
                              Text(
                                CurrencyHelper.formatAmount(
                                  order.pendingPaymentAmount,
                                  userCurrency,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          if (order.paymentReceivedDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Last payment: ${_formatDateTime(order.paymentReceivedDate!)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                          // ADD THIS VIEW HISTORY BUTTON
                          if (order.paymentReceivedAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (context) =>
                                          PaymentHistoryDialog(
                                            order: order,
                                            userCurrency: userCurrency,
                                          ),
                                    );
                                  },
                                  icon: Icon(Icons.history, size: 16),
                                  label: Text('View Payment History'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    side: BorderSide(color: Colors.purple),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 10),

            // Delivery Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${order.deliveredQuantity.toStringAsFixed(2)} / ${order.quantity.toStringAsFixed(2)} $productCurrency',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: order.deliveryPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  color: order.isFullyDelivered ? Colors.blue : Colors.orange,
                  minHeight: 6,
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.deliveryPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDeliveryDetails = !_showDeliveryDetails;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            _showDeliveryDetails ? 'Hide' : 'Details',
                            style: TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                          Icon(
                            _showDeliveryDetails
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Delivery Details (collapsible)
                if (_showDeliveryDetails)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Delivered:',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${order.deliveredQuantity.toStringAsFixed(2)} $productCurrency',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pending:', style: TextStyle(fontSize: 12)),
                              Text(
                                '${order.pendingDeliveryQuantity.toStringAsFixed(2)} $productCurrency',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          if (order.deliveredDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Last delivery: ${_formatDateTime(order.deliveredDate!)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                          // ADD THIS VIEW HISTORY BUTTON
                          if (order.deliveredQuantity > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (context) =>
                                          DeliveryHistoryDialog(order: order),
                                    );
                                  },
                                  icon: Icon(Icons.history, size: 16),
                                  label: Text('View Delivery History'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 15),

            // Action buttons - UPDATED FOR PARTIAL FUNCTIONALITY
            if (!order.isCompleted)
              _isProcessing
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Partial Payment Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: order.isFullyPaid
                                ? null
                                : () async {
                                    await _showPartialPaymentDialog(
                                      context,
                                      order,
                                    );
                                  },
                            icon: Icon(Icons.payment, size: 18),
                            label: Text(
                              order.isFullyPaid
                                  ? 'Fully Paid'
                                  : order.paymentReceivedAmount > 0
                                  ? 'Add Payment'
                                  : 'Mark Payment',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: order.isFullyPaid
                                  ? Colors.grey[300]
                                  : Colors.green,
                              foregroundColor: order.isFullyPaid
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 8),

                        // Partial Delivery Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: order.isFullyDelivered
                                ? null
                                : () async {
                                    await _showPartialDeliveryDialog(
                                      context,
                                      order,
                                    );
                                  },
                            icon: Icon(Icons.local_shipping, size: 18),
                            label: Text(
                              order.isFullyDelivered
                                  ? 'Fully Delivered'
                                  : order.deliveredQuantity > 0
                                  ? 'Add Delivery'
                                  : 'Mark Delivery',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: order.isFullyDelivered
                                  ? Colors.grey[300]
                                  : Colors.blue,
                              foregroundColor: order.isFullyDelivered
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 8),

                        // Undo buttons (only show if there's something to undo)
                        if (order.paymentReceivedAmount > 0 ||
                            order.deliveredQuantity > 0)
                          Row(
                            children: [
                              if (order.paymentReceivedAmount > 0)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleUndoPayment(
                                      context,
                                      order,
                                      sellOrderProvider,
                                    ),
                                    icon: Icon(Icons.undo, size: 16),
                                    label: Text(
                                      'Undo Payment',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: BorderSide(color: Colors.orange),
                                    ),
                                  ),
                                ),
                              if (order.paymentReceivedAmount > 0 &&
                                  order.deliveredQuantity > 0)
                                SizedBox(width: 8),
                              if (order.deliveredQuantity > 0)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleUndoDelivery(
                                      context,
                                      order,
                                      sellOrderProvider,
                                    ),
                                    icon: Icon(Icons.undo, size: 16),
                                    label: Text(
                                      'Undo Delivery',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: BorderSide(color: Colors.orange),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPartialPaymentDialog(
    BuildContext context,
    SellOrder order,
  ) async {
    final result = await showDialog(
      context: context,
      builder: (context) =>
          PartialPaymentDialog(order: order, userCurrency: widget.userCurrency),
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh the UI
    }
  }

  Future<void> _showPartialDeliveryDialog(
    BuildContext context,
    SellOrder order,
  ) async {
    final result = await showDialog(
      context: context,
      builder: (context) => PartialDeliveryDialog(order: order),
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh the UI
    }
  }

  Future<void> _handleUndoPayment(
    BuildContext context,
    SellOrder order,
    SellOrderProvider provider,
  ) async {
    if (_isProcessing) return;

    final confirmed = await _showUndoDialog(
      context,
      'Undo Payment',
      'How much payment would you like to undo?\n\n'
          'Current payment: ${CurrencyHelper.formatAmount(order.paymentReceivedAmount, widget.userCurrency)}\n'
          'Total amount: ${CurrencyHelper.formatAmount(order.totalAmount, widget.userCurrency)}',
      allowPartial:
          order.paymentReceivedAmount > 0 &&
          order.paymentReceivedAmount < order.totalAmount,
    );

    if (confirmed == null) return;

    setState(() => _isProcessing = true);

    try {
      bool success;
      if (confirmed is double) {
        // Partial undo
        success = await provider.undoPayment(order.id, amount: confirmed);
      } else {
        // Full undo
        success = await provider.undoPayment(order.id);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmed is double
                  ? '${CurrencyHelper.formatAmount(confirmed, widget.userCurrency)} payment undone'
                  : 'All payment undone',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh UI
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to undo payment'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleUndoDelivery(
    BuildContext context,
    SellOrder order,
    SellOrderProvider provider,
  ) async {
    if (_isProcessing) return;

    final confirmed = await _showUndoDialog(
      context,
      'Undo Delivery',
      'How much delivery would you like to undo?\n\n'
          'Current delivery: ${order.deliveredQuantity.toStringAsFixed(2)} ${order.productCode}\n'
          'Total quantity: ${order.quantity.toStringAsFixed(2)} ${order.productCode}',
      allowPartial:
          order.deliveredQuantity > 0 &&
          order.deliveredQuantity < order.quantity,
    );

    if (confirmed == null) return;

    setState(() => _isProcessing = true);

    try {
      bool success;
      if (confirmed is double) {
        // Partial undo
        success = await provider.undoDelivery(order.id, quantity: confirmed);
      } else {
        // Full undo
        success = await provider.undoDelivery(order.id);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmed is double
                  ? '${confirmed.toStringAsFixed(2)} ${order.productCode} delivery undone'
                  : 'All delivery undone',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh UI
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to undo delivery'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<dynamic> _showUndoDialog(
    BuildContext context,
    String title,
    String message, {
    bool allowPartial = false,
  }) async {
    if (!allowPartial) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Undo All', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );

      return confirmed == true;
    } else {
      // Show dialog with partial option
      final TextEditingController amountController = TextEditingController();

      return await showDialog<dynamic>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      SizedBox(height: 15),
                      if (allowPartial)
                        TextFormField(
                          controller: amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount to undo (optional)',
                            hintText: 'Leave empty to undo all',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Cancel'),
                  ),
                  if (allowPartial && amountController.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (amount != null && amount > 0) {
                          Navigator.pop(context, amount);
                        }
                      },
                      child: Text(
                        'Undo Partial',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Undo All',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    SellOrder order,
    SellOrderProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Sell Order'),
        content: Text('Are you sure you want to delete this sell order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        bool success = await provider.deleteSellOrder(order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Sell order deleted successfully'
                    : 'Failed to delete sell order',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ADD THESE CLASSES AT THE BOTTOM OF YOUR sell_orders_screen.dart FILE
// (AFTER THE PartialPaymentDialog and PartialDeliveryDialog classes)

class PaymentHistoryDialog extends StatefulWidget {
  final SellOrder order;
  final String userCurrency;

  const PaymentHistoryDialog({
    super.key,
    required this.order,
    required this.userCurrency,
  });

  @override
  _PaymentHistoryDialogState createState() => _PaymentHistoryDialogState();
}

class _PaymentHistoryDialogState extends State<PaymentHistoryDialog> {
  // ignore: unused_field
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
    final sellOrderProvider = Provider.of<SellOrderProvider>(
      context,
      listen: false,
    );

    try {
      _paymentHistory = await sellOrderProvider.getPaymentHistory(
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
                          widget.order.paymentReceivedAmount,
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
                                builder: (context) => EditPaymentDialog(
                                  order: widget.order,
                                  userCurrency: widget.userCurrency,
                                  paymentTransaction: payment,
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

class DeliveryHistoryDialog extends StatefulWidget {
  final SellOrder order;

  const DeliveryHistoryDialog({super.key, required this.order});

  @override
  _DeliveryHistoryDialogState createState() => _DeliveryHistoryDialogState();
}

class _DeliveryHistoryDialogState extends State<DeliveryHistoryDialog> {
  // ignore: unused_field
  late Future<List<Map<String, dynamic>>> _deliveryHistoryFuture;
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveryHistory = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveryHistory();
  }

  Future<void> _loadDeliveryHistory() async {
    setState(() => _isLoading = true);
    final sellOrderProvider = Provider.of<SellOrderProvider>(
      context,
      listen: false,
    );

    try {
      _deliveryHistory = await sellOrderProvider.getDeliveryHistory(
        widget.order.id,
      );
    } catch (e) {
      print('Error loading delivery history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.history, color: Colors.blue),
          SizedBox(width: 10),
          Text('Delivery History'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _deliveryHistory.isEmpty
            ? Center(child: Text('No delivery history found'))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Delivered:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.order.deliveredQuantity.toStringAsFixed(2)} ${widget.order.productCode}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _deliveryHistory.length,
                      itemBuilder: (context, index) {
                        final delivery = _deliveryHistory[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Icon(
                              Icons.local_shipping,
                              size: 20,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            '${(delivery['quantity'] as num).toStringAsFixed(2)} ${widget.order.productCode}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (delivery['trackingNumber'] != null)
                                Text('Tracking: ${delivery['trackingNumber']}'),
                              if (delivery['note'] != null)
                                Text('Note: ${delivery['note']}'),
                              Text(
                                'Date: ${_formatDate((delivery['date'] as Timestamp).toDate())}',
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
                                builder: (context) => EditDeliveryDialog(
                                  order: widget.order,
                                  deliveryTransaction: delivery,
                                ),
                              );

                              if (result != null && mounted) {
                                await _loadDeliveryHistory();
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

// Also make sure you have these two dialog classes (EditPaymentDialog and EditDeliveryDialog)
// If you don't have them, you need to add them too:

class EditPaymentDialog extends StatefulWidget {
  final SellOrder order;
  final String userCurrency;
  final Map<String, dynamic>? paymentTransaction;

  const EditPaymentDialog({
    super.key,
    required this.order,
    required this.userCurrency,
    this.paymentTransaction,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditPaymentDialogState createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isProcessing = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.paymentTransaction != null;

    if (_isEditing) {
      // Editing existing payment
      _amountController.text = (widget.paymentTransaction!['amount'] as num)
          .toStringAsFixed(2);
      _paymentMethod = widget.paymentTransaction!['paymentMethod'] ?? 'cash';
      _referenceController.text =
          widget.paymentTransaction!['referenceNumber'] ?? '';
      _noteController.text = widget.paymentTransaction!['note'] ?? '';
    } else {
      // New payment - initialize with remaining amount
      _amountController.text = widget.order.pendingPaymentAmount
          .toStringAsFixed(2);
    }
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
          Icon(Icons.edit, color: _isEditing ? Colors.orange : Colors.green),
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
                              order.paymentReceivedAmount,
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
                initialValue: _paymentMethod,
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
                Navigator.pop(context, {'deleted': true});
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
                      final success = await sellOrderProvider
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.orange : Colors.green,
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

class EditDeliveryDialog extends StatefulWidget {
  final SellOrder order;
  final Map<String, dynamic>? deliveryTransaction;

  const EditDeliveryDialog({
    super.key,
    required this.order,
    this.deliveryTransaction,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditDeliveryDialogState createState() => _EditDeliveryDialogState();
}

class _EditDeliveryDialogState extends State<EditDeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  final _trackingController = TextEditingController();
  bool _isProcessing = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.deliveryTransaction != null;

    if (_isEditing) {
      // Editing existing delivery
      _quantityController.text =
          (widget.deliveryTransaction!['quantity'] as num).toStringAsFixed(2);
      _trackingController.text =
          widget.deliveryTransaction!['trackingNumber'] ?? '';
      _noteController.text = widget.deliveryTransaction!['note'] ?? '';
    } else {
      // New delivery - initialize with remaining quantity
      _quantityController.text = widget.order.pendingDeliveryQuantity
          .toStringAsFixed(2);
    }
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
          Icon(Icons.edit, color: _isEditing ? Colors.orange : Colors.blue),
          SizedBox(width: 10),
          Text(_isEditing ? 'Edit Delivery' : 'Add Delivery'),
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
                  if (!_isEditing && quantity > pendingQuantity) {
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
        if (_isEditing)
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Delivery'),
                  content: Text(
                    'Are you sure you want to delete this delivery record?',
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
                Navigator.pop(context, {'deleted': true});
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
                    final quantity = double.parse(_quantityController.text);

                    if (_isEditing) {
                      // Update existing delivery
                      final transactionId = widget.deliveryTransaction!['id'];
                      final success = await sellOrderProvider
                          .updateDeliveryTransaction(
                            orderId: order.id,
                            transactionId: transactionId,
                            quantity: quantity,
                            trackingNumber: _trackingController.text.isNotEmpty
                                ? _trackingController.text
                                : null,
                            note: _noteController.text.isNotEmpty
                                ? _noteController.text
                                : null,
                          );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Delivery updated successfully'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                        Navigator.pop(context, {'updated': true});
                      }
                    } else {
                      // Add new delivery
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
                child: Text(_isEditing ? 'Update Delivery' : 'Record Delivery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.orange : Colors.blue,
                ),
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

// ADD THESE DIALOG CLASSES AT THE BOTTOM OF THE FILE:

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
          Icon(Icons.payment, color: Colors.green),
          SizedBox(width: 10),
          Text('Add Payment'),
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
                              order.paymentReceivedAmount,
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
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                initialValue: _paymentMethod,
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
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to record payment'),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green[800] : Colors.black,
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;

  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      labelPadding: EdgeInsets.symmetric(horizontal: 4),
      avatar: Icon(icon, size: 14, color: isActive ? Colors.white : color),
      label: Text(
        label,
        style: TextStyle(fontSize: 11, color: isActive ? Colors.white : color),
      ),
      backgroundColor: isActive ? color : color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
