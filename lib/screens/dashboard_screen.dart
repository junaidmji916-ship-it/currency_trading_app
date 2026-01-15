// File: lib/screens/dashboard_screen.dart - BLUE THEME
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sell_order_provider.dart';
import '../providers/buy_order_provider.dart';
import '../utils/currency_helper.dart';
import '../screens/buy_orders_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final userData = authProvider.userData;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF1565C0), // Blue text
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0), // Dark blue header
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
          const Divider(),
          _buildDrawerItem(Icons.settings, 'Settings', () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)), // Blue icons
      title: Text(title),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, String route) {
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
            const SizedBox(height: 9),
            _buildQuickStatsSection(context),
            const SizedBox(height: 9),
            _buildQuickActionsSection(context),
            const SizedBox(height: 9),
            _buildOrderSummarySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final userData = authProvider.userData;

    return Card(
      color: const Color(0xFF1565C0), // Dark blue
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Text(
                userData?['name']?.substring(0, 1) ?? 'U',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1565C0), // Blue text
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${userData?['name'] ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Currency: ${userData?['transactionCurrency'] ?? 'Not set'}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0), // Blue text
          ),
        ),
        const SizedBox(height: 5),
        Consumer3<SellOrderProvider, BuyOrderProvider, AuthProvider>(
          builder: (context, sellProvider, buyProvider, authProvider, child) {
            final userCurrency =
                authProvider.userData?['transactionCurrency'] ?? 'USD';
            final currencySymbol = CurrencyHelper.getSymbol(userCurrency);

            double totalSales = sellProvider.totalSales;
            double totalCost = buyProvider.totalCost;
            double profit = totalSales - totalCost;

            return GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              children: [
                StatCard(
                  title: 'Total Orders',
                  value:
                      '${sellProvider.totalOrders + buyProvider.totalOrders}',
                  icon: Icons.receipt,
                  color: Color(0xFF1976D2), // Blue
                  backgroundColor: Color(0xFFE3F2FD), // Light blue background
                ),
                StatCard(
                  title: 'Completed',
                  value:
                      '${sellProvider.completedOrders + buyProvider.completedOrders}',
                  icon: Icons.check_circle,
                  color: Color(0xFF1976D2), // Blue
                  backgroundColor: Color(0xFFE3F2FD), // Light blue background
                ),
                StatCard(
                  title: 'Pending',
                  value:
                      '${sellProvider.pendingOrders + buyProvider.pendingOrders}',
                  icon: Icons.pending_actions,
                  color: Color(0xFF1976D2), // Blue
                  backgroundColor: Color(0xFFE3F2FD), // Light blue background
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0), // Blue text
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            ActionButton(
              icon: Icons.sell,
              label: 'Create Sell',
              color: const Color(0xFF1976D2), // Blue
              onTap: () {
                Navigator.pushNamed(context, '/create_sell');
              },
            ),
            ActionButton(
              icon: Icons.shopping_cart,
              label: 'Create Buy',
              color: const Color(0xFF2196F3), // Light blue
              onTap: () {
                Navigator.pushNamed(context, '/create_buy');
              },
            ),
            ActionButton(
              icon: Icons.add,
              label: 'Add Product',
              color: const Color(0xFF42A5F5), // Blue
              onTap: () {
                Navigator.pushNamed(context, '/add_product');
              },
            ),
            ActionButton(
              icon: Icons.assessment,
              label: 'View Reports',
              color: const Color(0xFF0D47A1), // Dark blue
              onTap: () {
                Navigator.pushNamed(context, '/reports');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0), // Blue text
          ),
        ),
        const SizedBox(height: 8),

        // Buy Orders Card - Blue Theme
        Consumer<BuyOrderProvider>(
          builder: (context, buyProvider, child) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: Color(0xFFE3F2FD), // Light blue background
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Color(0xFFBBDEFB), width: 1),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuyOrdersScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF1976D2), // Blue circle
                        child: Icon(Icons.shopping_cart, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buy Orders',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0), // Dark blue text
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${buyProvider.totalOrders} orders • ${buyProvider.pendingOrders} pending',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1976D2), // Medium blue text
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFF1565C0)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Sell Orders Card - Blue Theme
        Consumer<SellOrderProvider>(
          builder: (context, sellProvider, child) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: Color(0xFFE3F2FD), // Light blue background
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Color(0xFFBBDEFB), width: 1),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/sell_orders');
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF1976D2), // Blue circle
                        child: Icon(Icons.sell, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sell Orders',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0), // Dark blue text
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${sellProvider.totalOrders} orders • ${sellProvider.pendingOrders} pending',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1976D2), // Medium blue text
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFF1565C0)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color titleColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.backgroundColor = Colors.white,
    this.titleColor = const Color(0xFF1565C0), // Blue default
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
  final Color color;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF1976D2), // Blue default
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                  fontSize: 12,
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
