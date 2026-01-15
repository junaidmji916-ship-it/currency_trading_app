// File: lib/screens/buy_orders_screen.dart - BLUE THEME
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/buy_order_model.dart';
import '../utils/currency_helper.dart';
import 'create_buy_order_screen.dart';
import 'edit_buy_order_screen.dart';
import 'partial_payment_buy_dialog.dart';
import 'payment_history_buy_dialog.dart';

class BuyOrdersScreen extends StatefulWidget {
  const BuyOrdersScreen({super.key});

  @override
  State<BuyOrdersScreen> createState() => _BuyOrdersScreenState();
}

class _BuyOrdersScreenState extends State<BuyOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Buy Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateBuyOrderScreen(),
                ),
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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            );
          }

          if (buyOrderProvider.buyOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'No buy orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap + to create your first buy order',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
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

  Future<void> _viewPaymentHistory(BuildContext context, BuyOrder order) async {
    try {
      final result = await showDialog(
        context: context,
        builder: (context) => PaymentHistoryBuyDialog(
          order: order,
          userCurrency: widget.userCurrency,
        ),
      );

      if (mounted && result == true) {
        setState(() {});
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
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFE3F2FD), // Light blue background
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFBBDEFB), width: 1),
      ),
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
                      ? const Color(0xFFE8F5E9) // Light green
                      : const Color(0xFFFFF3E0), // Light orange
                  child: Icon(
                    order.isCompleted ? Icons.check_circle : Icons.pending,
                    color: order.isCompleted
                        ? const Color(0xFF388E3C) // Green
                        : const Color(0xFFF57C00), // Orange
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.supplierName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0), // Dark blue
                        ),
                      ),
                      Text(
                        '${order.productName} (${order.productCode})',
                        style: const TextStyle(color: Color(0xFF1976D2)),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: order.isCompleted
                            ? const Color(0xFF388E3C) // Green
                            : const Color(0xFFF57C00), // Orange
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.isCompleted ? 'Completed' : 'Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Color(0xFF1565C0),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Order details with conversion rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DetailItem(
                  label: 'Date',
                  value: _formatDate(order.date),
                  labelColor: const Color(0xFF1976D2),
                  valueColor: const Color(0xFF0D47A1),
                ),
                DetailItem(
                  label: 'Amount',
                  value:
                      '${order.quantity.toStringAsFixed(2)} $productCurrency',
                  labelColor: const Color(0xFF1976D2),
                  valueColor: const Color(0xFF0D47A1),
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
                    labelColor: const Color(0xFF1976D2),
                    valueColor: const Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

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
                  labelColor: const Color(0xFF1976D2),
                  valueColor: const Color(0xFF388E3C), // Green for total
                ),
                // Show conversion info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _showReciprocalRate
                          ? '1 $productCurrency = ${order.rate.toStringAsFixed(4)} $userCurrency'
                          : '1 $userCurrency = ${reciprocalRate.toStringAsFixed(2)} $productCurrency',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1565C0),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap rate to toggle',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Payment Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment:',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1976D2).withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${order.paidAmount.toStringAsFixed(2)} / ${order.totalAmount.toStringAsFixed(2)} $userCurrency',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: order.paymentPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  color: order.isFullyPaid
                      ? const Color(0xFF388E3C) // Green
                      : const Color(0xFFF57C00), // Orange
                  minHeight: 6,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.paymentPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1976D2),
                      ),
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          Icon(
                            _showPaymentDetails
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 12,
                            color: const Color(0xFF1565C0),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFBBDEFB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Paid:',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                CurrencyHelper.formatAmount(
                                  order.paidAmount,
                                  userCurrency,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF388E3C), // Green
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pending:',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                CurrencyHelper.formatAmount(
                                  order.pendingPaymentAmount,
                                  userCurrency,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF57C00), // Orange
                                ),
                              ),
                            ],
                          ),
                          if (order.paymentDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Last payment: ${_formatDateTime(order.paymentDate!)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          if (order.paidAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _viewPaymentHistory(context, order),
                                      icon: const Icon(Icons.history, size: 16),
                                      label: const Text('View/Edit Payments'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF7B1FA2,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF7B1FA2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 15),

            // Action buttons for partial payments
            if (!order.isCompleted)
              _isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1565C0),
                        ),
                      ),
                    )
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
                                      buyOrderProvider,
                                    );
                                  },
                            icon: const Icon(Icons.payment, size: 18),
                            label: Text(
                              order.isFullyPaid
                                  ? 'Fully Paid'
                                  : order.paidAmount > 0
                                  ? 'Add Payment'
                                  : 'Mark Payment',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: order.isFullyPaid
                                  ? const Color(0xFFBDBDBD) // Grey
                                  : const Color(0xFF388E3C), // Green
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

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
                              icon: const Icon(Icons.undo, size: 16),
                              label: const Text(
                                'Undo Payment',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF57C00),
                                side: const BorderSide(
                                  color: Color(0xFFF57C00),
                                ),
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
    try {
      final result = await showDialog(
        context: context,
        builder: (context) => PartialPaymentBuyDialog(
          order: order,
          userCurrency: widget.userCurrency,
          note: '',
        ),
      );

      if (mounted && result == true) {
        setState(() {});
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

    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      bool success;
      if (confirmed is double) {
        // Partial undo
        success = await provider.undoPayment(
          order.id,
          amount: confirmed,
          note: 'Undo partial payment',
        );
      } else {
        // Full undo
        success = await provider.undoPayment(
          order.id,
          note: 'Undo full payment',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmed is double
                  ? '${CurrencyHelper.formatAmount(confirmed, widget.userCurrency)} payment undone'
                  : 'All payment undone',
            ),
            backgroundColor: const Color(0xFFF57C00),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFD32F2F),
            duration: const Duration(seconds: 3),
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
          backgroundColor: Colors.white,
          title: Text(title, style: const TextStyle(color: Color(0xFF1565C0))),
          content: Text(
            message,
            style: const TextStyle(color: Color(0xFF1976D2)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Undo All',
                style: TextStyle(color: Color(0xFFF57C00)),
              ),
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
                backgroundColor: Colors.white,
                title: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF1565C0)),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(color: Color(0xFF1976D2)),
                      ),
                      const SizedBox(height: 15),
                      if (allowPartial)
                        TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount to undo (optional)',
                            labelStyle: TextStyle(color: Color(0xFF1976D2)),
                            hintText: 'Leave empty to undo all',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF1565C0)),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
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
                    child: const Text('Cancel'),
                  ),
                  if (allowPartial && amountController.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (amount != null && amount > 0) {
                          Navigator.pop(context, amount);
                        }
                      },
                      child: const Text(
                        'Undo Partial',
                        style: TextStyle(color: Color(0xFFF57C00)),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Undo All',
                      style: TextStyle(color: Color(0xFFF57C00)),
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
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Buy Order',
          style: TextStyle(color: Color(0xFF1565C0)),
        ),
        content: const Text(
          'Are you sure you want to delete this buy order?',
          style: TextStyle(color: Color(0xFF1976D2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
              backgroundColor: success
                  ? const Color(0xFF388E3C)
                  : const Color(0xFFD32F2F),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: const Color(0xFFD32F2F),
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
  final Color labelColor;
  final Color valueColor;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.labelColor = const Color(0xFF1976D2),
    this.valueColor = const Color(0xFF0D47A1),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: labelColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF388E3C) : valueColor,
          ),
        ),
      ],
    );
  }
}
