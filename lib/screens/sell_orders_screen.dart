// File: lib/screens/sell_orders_screen.dart - BLUE THEME COLOR FIXES ONLY
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
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Sell Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateSellOrderScreen(),
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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            );
          }

          if (sellOrderProvider.sellOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'No sell orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap + to create your first sell order',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
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
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFE3F2FD), // Light blue background
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Color(0xFFBBDEFB), // Light blue border
          width: 1,
        ),
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
                      ? Colors.green[100]
                      : Colors.orange[100],
                  child: Icon(
                    order.isCompleted ? Icons.check_circle : Icons.pending,
                    color: order.isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0), // Dark blue text
                        ),
                      ),
                      Text(
                        '${order.productName} (${order.productCode})',
                        style: const TextStyle(
                          color: Color(0xFF1976D2), // Medium blue text
                        ),
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
                        color: order.isCompleted ? Colors.green : Colors.orange,
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
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
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
                        color: Color(0xFF1976D2), // Medium blue
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${order.paymentReceivedAmount.toStringAsFixed(2)} / ${order.totalAmount.toStringAsFixed(2)} $userCurrency',
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
                      ? const Color(0xFF388E3C)
                      : const Color(0xFF1976D2),
                  minHeight: 6,
                ),
                const SizedBox(height: 2),
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1976D2),
                            ), // Medium blue
                          ),
                          Icon(
                            _showPaymentDetails
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 12,
                            color: const Color(0xFF1976D2), // Medium blue
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                CurrencyHelper.formatAmount(
                                  order.paymentReceivedAmount,
                                  userCurrency,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF388E3C),
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                CurrencyHelper.formatAmount(
                                  order.pendingPaymentAmount,
                                  userCurrency,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF57C00),
                                ),
                              ),
                            ],
                          ),
                          if (order.paymentReceivedDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Last payment: ${_formatDateTime(order.paymentReceivedDate!)}',
                                style: const TextStyle(
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
                                  icon: const Icon(
                                    Icons.history,
                                    size: 16,
                                    color: Color(0xFF1976D2),
                                  ),
                                  label: const Text(
                                    'View Payment History',
                                    style: TextStyle(color: Color(0xFF1976D2)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF1976D2),
                                    ),
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

            const SizedBox(height: 10),

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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: order.deliveryPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  color: order.isFullyDelivered
                      ? const Color(0xFF1976D2)
                      : const Color(0xFFF57C00),
                  minHeight: 6,
                ),
                const SizedBox(height: 2),
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1976D2),
                            ), // Medium blue
                          ),
                          Icon(
                            _showDeliveryDetails
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 12,
                            color: const Color(0xFF1976D2), // Medium blue
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
                                'Delivered:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                '${order.deliveredQuantity.toStringAsFixed(2)} $productCurrency',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                '${order.pendingDeliveryQuantity.toStringAsFixed(2)} $productCurrency',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF57C00),
                                ),
                              ),
                            ],
                          ),
                          if (order.deliveredDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Last delivery: ${_formatDateTime(order.deliveredDate!)}',
                                style: const TextStyle(
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
                                  icon: const Icon(
                                    Icons.history,
                                    size: 16,
                                    color: Color(0xFF1976D2),
                                  ),
                                  label: const Text(
                                    'View Delivery History',
                                    style: TextStyle(color: Color(0xFF1976D2)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF1976D2),
                                    ),
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

            const SizedBox(height: 15),

            // Action buttons - UPDATED FOR PARTIAL FUNCTIONALITY
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
                                    await _showPartialPaymentDialog(
                                      context,
                                      order,
                                    );
                                  },
                            icon: const Icon(Icons.payment, size: 18),
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
                                  : const Color(0xFF388E3C),
                              foregroundColor: order.isFullyPaid
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

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
                            icon: const Icon(Icons.local_shipping, size: 18),
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
                                  : const Color(0xFF1976D2),
                              foregroundColor: order.isFullyDelivered
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

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
                              if (order.paymentReceivedAmount > 0 &&
                                  order.deliveredQuantity > 0)
                                const SizedBox(width: 8),
                              if (order.deliveredQuantity > 0)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleUndoDelivery(
                                      context,
                                      order,
                                      sellOrderProvider,
                                    ),
                                    icon: const Icon(Icons.undo, size: 16),
                                    label: const Text(
                                      'Undo Delivery',
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
            backgroundColor: const Color(0xFFF57C00),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh UI
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to undo payment'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
            backgroundColor: const Color(0xFFF57C00),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh UI
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to undo delivery'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Undo All',
                style: TextStyle(color: Colors.orange),
              ),
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
                      const SizedBox(height: 15),
                      if (allowPartial)
                        TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount to undo (optional)',
                            hintText: 'Leave empty to undo all',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
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
        title: const Text('Delete Sell Order'),
        content: const Text('Are you sure you want to delete this sell order?'),
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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF1565C0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Info Card - BLUE THEME
            Card(
              color: const Color(0xFFE3F2FD),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFBBDEFB), width: 1),
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
                          widget.order.customerName,
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
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.order.isFullyPaid
                              ? const Color(0xFFC8E6C9)
                              : const Color(0xFFFFE0B2),
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
                              ? const Color(0xFF388E3C)
                              : const Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1565C0),
                      ),
                    ),
                  )
                : _paymentHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No payment history found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Payments:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              widget.order.paymentReceivedAmount,
                              widget.userCurrency,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _paymentHistory.length,
                          itemBuilder: (context, index) {
                            final payment = _paymentHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: const Color(0xFFF0F8FF),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: Color(0xFFBBDEFB),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  child: Icon(
                                    Icons.payment,
                                    size: 20,
                                    color: const Color(0xFF388E3C),
                                  ),
                                ),
                                title: Text(
                                  CurrencyHelper.formatAmount(
                                    (payment['amount'] as num).toDouble(),
                                    widget.userCurrency,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Method: ${payment['paymentMethod'] ?? 'Not specified'}',
                                      style: const TextStyle(
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                    if (payment['referenceNumber'] != null)
                                      Text(
                                        'Ref: ${payment['referenceNumber']}',
                                      ),
                                    if (payment['note'] != null)
                                      Text(
                                        'Note: ${payment['note']}',
                                        style: const TextStyle(
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                    Text(
                                      'Date: ${_formatDate((payment['date'] as Timestamp).toDate())}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Color(0xFF1976D2),
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
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF1976D2)),
                ),
              ),
            ),
          ],
        ),
      ),
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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF1565C0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Info Card - BLUE THEME
            Card(
              color: const Color(0xFFE3F2FD),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFBBDEFB), width: 1),
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
                          widget.order.customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${widget.order.quantity.toStringAsFixed(2)} ${widget.order.productCode}',
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
                        color: widget.order.isFullyDelivered
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.order.isFullyDelivered
                              ? const Color(0xFFC8E6C9)
                              : const Color(0xFFFFE0B2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.order.isFullyDelivered
                            ? 'Fully Delivered'
                            : 'Partially Delivered',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: widget.order.isFullyDelivered
                              ? const Color(0xFF388E3C)
                              : const Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1565C0),
                      ),
                    ),
                  )
                : _deliveryHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No delivery history found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Delivered:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.order.deliveredQuantity.toStringAsFixed(2)} ${widget.order.productCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _deliveryHistory.length,
                          itemBuilder: (context, index) {
                            final delivery = _deliveryHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: const Color(0xFFF0F8FF),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: Color(0xFFBBDEFB),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE3F2FD),
                                  child: Icon(
                                    Icons.local_shipping,
                                    size: 20,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                                title: Text(
                                  '${(delivery['quantity'] as num).toStringAsFixed(2)} ${widget.order.productCode}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (delivery['trackingNumber'] != null)
                                      Text(
                                        'Tracking: ${delivery['trackingNumber']}',
                                        style: const TextStyle(
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                    if (delivery['note'] != null)
                                      Text(
                                        'Note: ${delivery['note']}',
                                        style: const TextStyle(
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                    Text(
                                      'Date: ${_formatDate((delivery['date'] as Timestamp).toDate())}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Color(0xFF1976D2),
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
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF1976D2)),
                ),
              ),
            ),
          ],
        ),
      ),
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
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.edit, color: _isEditing ? Colors.orange : Colors.green),
          const SizedBox(width: 10),
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
              // Payment Summary - BLUE THEME
              Card(
                color: const Color(0xFFE3F2FD),
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
                              order.paymentReceivedAmount,
                              widget.userCurrency,
                            ),
                            style: const TextStyle(color: Color(0xFF388E3C)),
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
                            style: const TextStyle(color: Color(0xFFF57C00)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: paidPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${paidPercentage.toStringAsFixed(1)}% Paid',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                  hintText: 'Enter amount',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
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

              const SizedBox(height: 15),

              // Payment Method
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
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

              const SizedBox(height: 15),

              // Reference Number
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (Optional)',
                  hintText: 'e.g., Transaction ID, Cheque No.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),

              const SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
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
                  title: const Text('Delete Payment'),
                  content: const Text(
                    'Are you sure you want to delete this payment record?',
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        _isProcessing
            ? const CircularProgressIndicator()
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
                            content: const Text('Payment updated successfully'),
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
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.edit, color: _isEditing ? Colors.orange : Colors.blue),
          const SizedBox(width: 10),
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
              // Delivery Summary - BLUE THEME
              Card(
                color: const Color(0xFFE3F2FD),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Quantity:',
                            style: TextStyle(color: Color(0xFF1976D2)),
                          ),
                          Text(
                            '${order.quantity.toStringAsFixed(2)} ${order.productCode}',
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
                            'Already Delivered:',
                            style: TextStyle(color: Color(0xFF1976D2)),
                          ),
                          Text(
                            '${order.deliveredQuantity.toStringAsFixed(2)} ${order.productCode}',
                            style: const TextStyle(color: Color(0xFF1976D2)),
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
                            '${pendingQuantity.toStringAsFixed(2)} ${order.productCode}',
                            style: const TextStyle(color: Color(0xFFF57C00)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: deliveredPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deliveredPercentage.toStringAsFixed(1)}% Delivered',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Delivery Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Delivery Quantity*',
                  hintText: 'Enter quantity',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.format_list_numbered),
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

              const SizedBox(height: 15),

              // Tracking Number
              TextFormField(
                controller: _trackingController,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number (Optional)',
                  hintText: 'e.g., AWB, Tracking ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
              ),

              const SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
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
                  title: const Text('Delete Delivery'),
                  content: const Text(
                    'Are you sure you want to delete this delivery record?',
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        _isProcessing
            ? const CircularProgressIndicator()
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
                            content: const Text(
                              'Delivery updated successfully',
                            ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.orange : Colors.blue,
                ),
                child: Text(_isEditing ? 'Update Delivery' : 'Record Delivery'),
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
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.payment, color: Colors.green),
          const SizedBox(width: 10),
          const Text('Add Payment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary - BLUE THEME
              Card(
                color: const Color(0xFFE3F2FD),
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
                              order.paymentReceivedAmount,
                              widget.userCurrency,
                            ),
                            style: const TextStyle(color: Color(0xFF388E3C)),
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
                            style: const TextStyle(color: Color(0xFFF57C00)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: paidPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${paidPercentage.toStringAsFixed(1)}% Paid',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                  hintText: 'Enter amount',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
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

              const SizedBox(height: 15),

              // Payment Method
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
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

              const SizedBox(height: 15),

              // Reference Number
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (Optional)',
                  hintText: 'e.g., Transaction ID, Cheque No.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),

              const SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
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
          child: const Text('Cancel'),
        ),
        _isProcessing
            ? const CircularProgressIndicator()
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
                            content: const Text('Failed to record payment'),
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
                child: const Text('Record Payment'),
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
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.blue),
          const SizedBox(width: 10),
          const Text('Add Delivery'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Summary - BLUE THEME
              Card(
                color: const Color(0xFFE3F2FD),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Quantity:',
                            style: TextStyle(color: Color(0xFF1976D2)),
                          ),
                          Text(
                            '${order.quantity.toStringAsFixed(2)} ${order.productCode}',
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
                            'Already Delivered:',
                            style: TextStyle(color: Color(0xFF1976D2)),
                          ),
                          Text(
                            '${order.deliveredQuantity.toStringAsFixed(2)} ${order.productCode}',
                            style: const TextStyle(color: Color(0xFF1976D2)),
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
                            '${pendingQuantity.toStringAsFixed(2)} ${order.productCode}',
                            style: const TextStyle(color: Color(0xFFF57C00)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: deliveredPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deliveredPercentage.toStringAsFixed(1)}% Delivered',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Delivery Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Delivery Quantity*',
                  hintText: 'Enter quantity',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.format_list_numbered),
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

              const SizedBox(height: 15),

              // Tracking Number
              TextFormField(
                controller: _trackingController,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number (Optional)',
                  hintText: 'e.g., AWB, Tracking ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
              ),

              const SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
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
          child: const Text('Cancel'),
        ),
        _isProcessing
            ? const CircularProgressIndicator()
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
                            content: const Text('Failed to record delivery'),
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
                child: const Text('Record Delivery'),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF388E3C) : Colors.black,
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
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
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
