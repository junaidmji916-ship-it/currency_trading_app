// File: lib/screens/dashboard_screen.dart
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sell_order_provider.dart';
import '../providers/buy_order_provider.dart';
import '../models/sell_order_model.dart';
import '../utils/currency_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, userData),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawer(BuildContext context, Map<String, dynamic>? userData) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userData?['name'] ?? 'User'),
            accountEmail: Text(userData?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userData?['name']?.substring(0, 1) ?? 'U',
                style: TextStyle(
                  fontSize: 24,
                  color: const Color.fromARGB(255, 0, 47, 85),
                ),
              ),
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(Icons.currency_exchange, 'Products', () {
            Navigator.pop(context);
            _navigateTo(context, 'products');
          }),
          _buildDrawerItem(Icons.sell, 'Sell Orders', () {
            Navigator.pop(context);
            _navigateTo(context, 'sell_orders');
          }),
          _buildDrawerItem(Icons.shopping_cart, 'Buy Orders', () {
            Navigator.pop(context);
            _navigateTo(context, 'buy_orders');
          }),
          _buildDrawerItem(Icons.people, 'Suppliers', () {
            Navigator.pop(context);
            _navigateTo(context, 'suppliers');
          }),
          _buildDrawerItem(Icons.assessment, 'Reports', () {
            Navigator.pop(context);
            _navigateTo(context, 'reports');
          }),
          Divider(),
          _buildDrawerItem(Icons.settings, 'Settings', () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  void _navigateTo(BuildContext context, String route) {
    // Import your screens at the top of the file
    // We'll use a switch case to navigate
    switch (route) {
      case 'products':
        Navigator.pushNamed(context, '/products');
        break;
      case 'sell_orders':
        Navigator.pushNamed(context, '/sell_orders');
        break;
      case 'buy_orders':
        Navigator.pushNamed(context, '/buy_orders');
        break;
      case 'suppliers':
        Navigator.pushNamed(context, '/suppliers');
        break;
      case 'reports':
        Navigator.pushNamed(context, '/reports');
        break;
    }
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context),
            SizedBox(height: 30),
            _buildQuickStatsSection(context),
            SizedBox(height: 30),
            _buildQuickActionsSection(context),
            SizedBox(height: 30),
            _buildPendingTransactionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final userData = authProvider.userData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${userData?['name'] ?? 'User'}!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Transaction Currency: ${userData?['transactionCurrency'] ?? 'Not set'}',
              style: TextStyle(
                fontSize: 16,
                color: const Color.fromARGB(255, 1, 9, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Consumer3<SellOrderProvider, BuyOrderProvider, AuthProvider>(
          builder: (context, sellProvider, buyProvider, authProvider, child) {
            final userCurrency =
                authProvider.userData?['transactionCurrency'] ?? 'USD';
            final currencySymbol = CurrencyHelper.getSymbol(userCurrency);

            double totalSales = sellProvider.totalSales;
            double totalCost = buyProvider.totalCost;
            double profit = totalSales - totalCost;

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: EdgeInsets.symmetric(horizontal: 5),
              children: [
                StatCard(
                  title: 'Total Orders',
                  value:
                      '${sellProvider.totalOrders + buyProvider.totalOrders}',
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                StatCard(
                  title: 'Pending',
                  value:
                      '${sellProvider.pendingOrders + buyProvider.pendingOrders}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                StatCard(
                  title: 'Completed',
                  value:
                      '${sellProvider.completedOrders + buyProvider.completedOrders}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Profit/Loss',
                  value: '$currencySymbol${profit.toStringAsFixed(2)}',
                  icon: profit >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: profit >= 0 ? Colors.purple : Colors.red,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            ActionButton(
              icon: Icons.add,
              label: 'Add Product',
              onTap: () {
                Navigator.pushNamed(context, '/add_product');
              },
            ),
            ActionButton(
              icon: Icons.sell,
              label: 'Create Sell',
              onTap: () {
                Navigator.pushNamed(context, '/create_sell');
              },
            ),
            ActionButton(
              icon: Icons.shopping_cart,
              label: 'Create Buy',
              onTap: () {
                Navigator.pushNamed(context, '/create_buy');
              },
            ),
            ActionButton(
              icon: Icons.assessment,
              label: 'View Reports',
              onTap: () {
                Navigator.pushNamed(context, '/reports');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingTransactionsSection(BuildContext context) {
    return Consumer3<AuthProvider, SellOrderProvider, BuyOrderProvider>(
      builder: (context, authProvider, sellProvider, buyProvider, child) {
        try {
          final userCurrency =
              authProvider.userData?['transactionCurrency'] ?? 'USD';

          // Get pending orders safely
          List<dynamic> pendingSellOrders = [];
          List<dynamic> pendingBuyOrders = [];

          try {
            pendingSellOrders = sellProvider.getPendingOrders();
          } catch (e) {
            print('Error getting pending sell orders: $e');
          }

          try {
            pendingBuyOrders = buyProvider.getPendingOrders();
          } catch (e) {
            print('Error getting pending buy orders: $e');
          }

          final allPendingOrders = [...pendingSellOrders, ...pendingBuyOrders];

          // If no pending orders, return empty container
          if (allPendingOrders.isEmpty) {
            return SizedBox(height: 0);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Pending Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Chip(
                    label: Text('${allPendingOrders.length}'),
                    backgroundColor: Colors.orange[100],
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Pending Orders List - Limited to 5 items
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: allPendingOrders.length > 5
                    ? 5
                    : allPendingOrders.length,
                itemBuilder: (context, index) {
                  try {
                    final order = allPendingOrders[index];
                    final isSell = order is SellOrder;

                    return DashboardPendingOrderCard(
                      order: order,
                      isSell: isSell,
                      userCurrency: userCurrency,
                    );
                  } catch (e) {
                    print('Error building pending order card: $e');
                    return SizedBox(height: 0);
                  }
                },
              ),

              if (allPendingOrders.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/sell_orders');
                      },
                      child: Text(
                        'View all ${allPendingOrders.length} pending transactions',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
            ],
          );
        } catch (e) {
          print('Error in pending transactions section: $e');
          return SizedBox(height: 0);
        }
      },
    );
  }
}

// Helper Widgets

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: Colors.blue),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPendingOrderCard extends StatelessWidget {
  final dynamic order;
  final bool isSell;
  final String userCurrency;

  const DashboardPendingOrderCard({
    super.key,
    required this.order,
    required this.isSell,
    required this.userCurrency,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Safely extract order details
      String name = isSell
          ? (order.customerName ?? 'Unknown Customer')
          : (order.supplierName ?? 'Unknown Supplier');
      String product =
          '${order.productName ?? 'Unknown'} (${order.productCode ?? 'N/A'})';
      double amount = order.totalAmount ?? 0.0;
      bool isPaid = isSell
          ? (order.paymentReceived ?? false)
          : (order.paid ?? false);
      bool isDelivered = isSell ? (order.delivered ?? false) : false;
      bool isPending = (order.status ?? 'pending') == 'pending';

      // Extract partial payment/delivery data safely
      double paymentReceivedAmount = isSell
          ? (order.paymentReceivedAmount ?? 0.0)
          : (order.paidAmount ?? 0.0);
      double deliveredQuantity = isSell
          ? (order.deliveredQuantity ?? 0.0)
          : 0.0;
      double paymentPercentage = amount > 0
          ? (paymentReceivedAmount / amount) * 100
          : 0.0;
      double deliveryPercentage =
          isSell && order.quantity != null && order.quantity! > 0
          ? (deliveredQuantity / order.quantity!) * 100
          : 0.0;

      return Card(
        margin: EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isPending
                        ? Colors.orange[100]
                        : Colors.green[100],
                    radius: 16,
                    child: Icon(
                      isSell ? Icons.sell : Icons.shopping_cart,
                      size: 14,
                      color: isPending ? Colors.orange : Colors.green,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          product,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyHelper.formatAmount(amount, userCurrency),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSell
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.edit, size: 16, color: Colors.grey),
                        onPressed: () {
                          // Edit functionality
                          if (isSell) {
                            Navigator.pushNamed(context, '/sell_orders');
                          } else {
                            Navigator.pushNamed(context, '/buy_orders');
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 10),

              // Status indicators
              Row(
                children: [
                  _buildStatusIndicator(
                    icon: Icons.payment,
                    label: 'Paid',
                    isActive: isPaid,
                    color: Colors.green,
                  ),
                  if (isSell) ...[
                    SizedBox(width: 8),
                    _buildStatusIndicator(
                      icon: Icons.local_shipping,
                      label: 'Delivered',
                      isActive: isDelivered,
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),

              SizedBox(height: 10),

              // Payment Progress (for both sell and buy orders)
              Container(
                margin: EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment: ${CurrencyHelper.formatAmount(paymentReceivedAmount, userCurrency)}/${CurrencyHelper.formatAmount(amount, userCurrency)}',
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          '${paymentPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: paymentPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      color: paymentPercentage >= 100
                          ? Colors.green
                          : Colors.orange,
                      minHeight: 4,
                    ),
                  ],
                ),
              ),

              // Delivery Progress (for sell orders only)
              if (isSell)
                Container(
                  margin: EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery: ${deliveredQuantity.toStringAsFixed(2)}/${order.quantity?.toStringAsFixed(2) ?? '0'} ${order.productCode ?? ''}',
                            style: TextStyle(fontSize: 10),
                          ),
                          Text(
                            '${deliveryPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      LinearProgressIndicator(
                        value: deliveryPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: deliveryPercentage >= 100
                            ? Colors.blue
                            : Colors.orange,
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 10),

              // Action buttons with undo functionality
              if (isPending || isPaid || isDelivered)
                Row(
                  children: [
                    if (isSell) ...[
                      Expanded(
                        child: _buildActionButtonWithUndo(
                          label: isPaid ? 'Undo Paid' : 'Add Payment',
                          icon: isPaid ? Icons.undo : Icons.payment,
                          isActive: isPaid,
                          color: Colors.green,
                          onPressed: () async {
                            if (isPaid) {
                              await _handleUndoPaid(context, order, isSell);
                            } else {
                              // Navigate to sell order screen for partial payment
                              Navigator.pushNamed(context, '/sell_orders');
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButtonWithUndo(
                          label: isDelivered ? 'Undo Delivery' : 'Add Delivery',
                          icon: isDelivered ? Icons.undo : Icons.local_shipping,
                          isActive: isDelivered,
                          color: Colors.blue,
                          onPressed: () async {
                            if (isDelivered) {
                              await _handleUndoDelivered(
                                context,
                                order,
                                isSell,
                              );
                            } else {
                              // Navigate to sell order screen for partial delivery
                              Navigator.pushNamed(context, '/sell_orders');
                            }
                          },
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: _buildActionButtonWithUndo(
                          label: isPaid ? 'Undo Paid' : 'Mark Paid',
                          icon: isPaid ? Icons.undo : Icons.payment,
                          isActive: isPaid,
                          color: Colors.green,
                          onPressed: () async {
                            if (isPaid) {
                              await _handleUndoPaid(context, order, isSell);
                            } else {
                              await _handleMarkPaid(context, order, isSell);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building DashboardPendingOrderCard: $e');
      return SizedBox(height: 0);
    }
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isActive ? Colors.white : color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonWithUndo({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final isUndo = label.startsWith('Undo');

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        backgroundColor: isUndo
            ? const Color.fromARGB(255, 151, 196, 238)
            : (isActive ? Colors.grey[300] : color),
        foregroundColor: isUndo
            ? Colors.white
            : (isActive ? Colors.grey[600] : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Future<void> _handleMarkPaid(
    BuildContext context,
    dynamic order,
    bool isSell,
  ) async {
    try {
      if (isSell) {
        final sellProvider = Provider.of<SellOrderProvider>(
          context,
          listen: false,
        );
        bool success = await sellProvider.updateSellOrderStatus(
          orderId: order.id,
          paymentReceived: true,
        );

        if (success) {
          await sellProvider.loadSellOrders();
          _showSuccessMessage(context, 'Payment marked as received');
        } else {
          _showErrorMessage(context, 'Failed to mark as paid');
        }
      } else {
        final buyProvider = Provider.of<BuyOrderProvider>(
          context,
          listen: false,
        );
        bool success = await buyProvider.updateBuyOrderStatus(
          orderId: order.id,
          paid: true,
        );

        if (success) {
          await buyProvider.loadBuyOrders();
          _showSuccessMessage(context, 'Payment marked as received');
        } else {
          _showErrorMessage(context, 'Failed to mark as paid');
        }
      }
    } catch (e) {
      print('Error marking as paid: $e');
      _showErrorMessage(context, 'Error: ${e.toString()}');
    }
  }

  Future<void> _handleMarkDelivered(
    BuildContext context,
    dynamic order,
    bool isSell,
  ) async {
    try {
      if (isSell) {
        final sellProvider = Provider.of<SellOrderProvider>(
          context,
          listen: false,
        );
        bool success = await sellProvider.updateSellOrderStatus(
          orderId: order.id,
          delivered: true,
        );

        if (success) {
          await sellProvider.loadSellOrders();
          _showSuccessMessage(context, 'Order marked as delivered');
        } else {
          _showErrorMessage(context, 'Failed to mark as delivered');
        }
      }
    } catch (e) {
      print('Error marking as delivered: $e');
      _showErrorMessage(context, 'Error: ${e.toString()}');
    }
  }

  Future<void> _handleUndoPaid(
    BuildContext context,
    dynamic order,
    bool isSell,
  ) async {
    try {
      if (isSell) {
        final sellProvider = Provider.of<SellOrderProvider>(
          context,
          listen: false,
        );
        bool success = await sellProvider.undoPayment(order.id);

        if (success) {
          await sellProvider.loadSellOrders();
          _showSuccessMessage(
            context,
            'Payment undone - Status set to pending',
          );
        } else {
          _showErrorMessage(context, 'Failed to undo payment');
        }
      } else {
        final buyProvider = Provider.of<BuyOrderProvider>(
          context,
          listen: false,
        );
        bool success = await buyProvider.undoPayment(order.id);

        if (success) {
          await buyProvider.loadBuyOrders();
          _showSuccessMessage(
            context,
            'Payment undone - Status set to pending',
          );
        } else {
          _showErrorMessage(context, 'Failed to undo payment');
        }
      }
    } catch (e) {
      print('Error undoing paid: $e');
      _showErrorMessage(context, 'Error: ${e.toString()}');
    }
  }

  Future<void> _handleUndoDelivered(
    BuildContext context,
    dynamic order,
    bool isSell,
  ) async {
    try {
      if (isSell) {
        final sellProvider = Provider.of<SellOrderProvider>(
          context,
          listen: false,
        );
        bool success = await sellProvider.undoDelivery(order.id);

        if (success) {
          await sellProvider.loadSellOrders();
          _showSuccessMessage(
            context,
            'Delivery undone - Status set to pending',
          );
        } else {
          _showErrorMessage(context, 'Failed to undo delivery');
        }
      }
    } catch (e) {
      print('Error undoing delivery: $e');
      _showErrorMessage(context, 'Error: ${e.toString()}');
    }
  }

  void _showSuccessMessage(BuildContext context, String message) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showErrorMessage(BuildContext context, String message) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }
}

Widget _buildStatusIndicator({
  required IconData icon,
  required String label,
  required bool isActive,
  required Color color,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isActive ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isActive ? color : color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: isActive ? Colors.white : color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.white : color,
          ),
        ),
      ],
    ),
  );
}

void _handleStatusUpdate(
  BuildContext context,
  dynamic order,
  bool isSell,
  String action,
) {
  // This is a simplified handler - implement your actual provider calls here
  // For now, just show a snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Marked as $action - Please refresh'),
      duration: Duration(seconds: 2),
    ),
  );
}
