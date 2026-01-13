// File: lib/screens/buy_orders_screen.dart - COMPLETE UPDATED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/buy_order_model.dart';
import '../utils/currency_helper.dart';
import 'create_buy_order_screen.dart';
import 'edit_buy_order_screen.dart';
import 'partial_payment_buy_dialog.dart'; // For advanced dialog
import 'payment_history_buy_dialog.dart'; // Keep this

class BuyOrdersScreen extends StatefulWidget {
  const BuyOrdersScreen({super.key});

  @override
  State<BuyOrdersScreen> createState() => _BuyOrdersScreenState();
}

class _BuyOrdersScreenState extends State<BuyOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateBuyOrderScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<BuyOrderProvider, AuthProvider>(
        builder: (context, buyOrderProvider, authProvider, child) {
          final userCurrency =
              authProvider.userData?['transactionCurrency'] ?? 'USD';

          if (buyOrderProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (buyOrderProvider.buyOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No buy orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap + to create your first buy order',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: buyOrderProvider.buyOrders.length,
            itemBuilder: (context, index) {
              BuyOrder order = buyOrderProvider.buyOrders[index];
              final productCurrency = order.productCode;
              return BuyOrderCard(
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

class BuyOrderCard extends StatefulWidget {
  final BuyOrder order;
  final String userCurrency;
  final String productCurrency;

  const BuyOrderCard({
    super.key,
    required this.order,
    required this.userCurrency,
    required this.productCurrency,
  });

  @override
  State<BuyOrderCard> createState() => _BuyOrderCardState();
}

class _BuyOrderCardState extends State<BuyOrderCard> {
  bool _isProcessing = false;
  bool _showReciprocalRate = false;
  bool _showPaymentDetails = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final userCurrency = widget.userCurrency;
    final productCurrency = widget.productCurrency;
    final buyOrderProvider = Provider.of<BuyOrderProvider>(
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
                        order.supplierName,
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
                                  EditBuyOrderScreen(order: order),
                            ),
                          );
                        } else if (value == 'delete') {
                          await _showDeleteDialog(
                            context,
                            order,
                            buyOrderProvider,
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
                      '${order.paidAmount.toStringAsFixed(2)} / ${order.totalAmount.toStringAsFixed(2)} $userCurrency',
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
                                  order.paidAmount,
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
                          if (order.paymentDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Last payment: ${_formatDateTime(order.paymentDate!)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        if (order.paidAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => PaymentHistoryBuyDialog(
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

            SizedBox(height: 15),

            // Action buttons for partial payments
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
                                    final buyOrderProvider =
                                        Provider.of<BuyOrderProvider>(
                                          context,
                                          listen: false,
                                        );
                                    await _showPartialPaymentDialog(
                                      context,
                                      order,
                                      buyOrderProvider, // Pass provider
                                    );
                                  },
                            icon: Icon(Icons.payment, size: 18),
                            label: Text(
                              order.isFullyPaid
                                  ? 'Fully Paid'
                                  : order.paidAmount > 0
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

                        // Undo payment button (only show if there's something to undo)
                        if (order.paidAmount > 0)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _handleUndoPayment(
                                context,
                                order,
                                buyOrderProvider,
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
                      ],
                    ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPartialPaymentDialog(
    BuildContext context,
    BuyOrder order,
    BuyOrderProvider buyOrderProvider,
  ) async {
    final result = await showDialog(
      context: context,
      builder: (context) => PartialPaymentBuyDialog(
        order: order,
        userCurrency: widget.userCurrency,
      ),
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh the UI
    }
  }

  Future<void> _handlePartialPayment(
    BuildContext context,
    BuyOrder order,
    BuyOrderProvider provider,
    double amount,
  ) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      bool success = await provider.addPartialPayment(
        orderId: order.id,
        amount: amount,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh UI
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add payment'),
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

  Future<void> _handleUndoPayment(
    BuildContext context,
    BuyOrder order,
    BuyOrderProvider provider,
  ) async {
    if (_isProcessing) return;

    final confirmed = await _showUndoDialog(
      context,
      'Undo Payment',
      'How much payment would you like to undo?\n\n'
          'Current payment: ${CurrencyHelper.formatAmount(order.paidAmount, widget.userCurrency)}\n'
          'Total amount: ${CurrencyHelper.formatAmount(order.totalAmount, widget.userCurrency)}',
      allowPartial:
          order.paidAmount > 0 && order.paidAmount < order.totalAmount,
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
      final amountController = TextEditingController();

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
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null) {
                                return 'Please enter valid number';
                              }
                              if (amount <= 0) {
                                return 'Amount must be greater than 0';
                              }
                            }
                            return null;
                          },
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
    BuyOrder order,
    BuyOrderProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Buy Order'),
        content: Text('Are you sure you want to delete this buy order?'),
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
        bool success = await provider.deleteBuyOrder(order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Buy order deleted successfully'
                    : 'Failed to delete buy order',
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
