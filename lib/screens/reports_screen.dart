// File: lib/screens/reports_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reports_provider.dart';
import '../providers/sell_order_provider.dart';
import '../providers/buy_order_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/currency_helper.dart';
import '../services/pdf_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        actions: [
          // Export Button
          PopupMenuButton<String>(
            onSelected: (value) => _handleExportAction(value, context),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sales',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export Sales Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'purchases',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Export Purchases Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profit',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export Profit & Loss Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'comprehensive',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Export Comprehensive Report'),
                  ],
                ),
              ),
            ],
            icon: _isExporting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body:
          Consumer4<
            ReportsProvider,
            SellOrderProvider,
            BuyOrderProvider,
            AuthProvider
          >(
            builder:
                (
                  context,
                  reportsProvider,
                  sellProvider,
                  buyProvider,
                  authProvider,
                  child,
                ) {
                  final userCurrency =
                      authProvider.userData?['transactionCurrency'] ?? 'USD';
                  final userName = authProvider.userData?['name'] ?? 'User';

                  // Get filtered orders
                  final filteredSellOrders = reportsProvider
                      .getFilteredSellOrders(sellProvider.sellOrders);
                  final filteredBuyOrders = reportsProvider
                      .getFilteredBuyOrders(buyProvider.buyOrders);

                  // Calculate totals
                  final totals = reportsProvider.calculateTotals(
                    sellOrders: filteredSellOrders,
                    buyOrders: filteredBuyOrders,
                  );

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Controls
                          _buildFilterControls(context, reportsProvider),

                          SizedBox(height: 20),

                          // Quick Export Buttons
                          _buildQuickExportButtons(
                            context,
                            reportsProvider,
                            sellProvider,
                            buyProvider,
                            authProvider,
                            userName,
                            userCurrency,
                          ),

                          SizedBox(height: 20),

                          // Summary Cards
                          _buildSummaryCards(totals, userCurrency),

                          SizedBox(height: 20),

                          // Sales Report
                          _buildTransactionSection(
                            title: 'Sales Report',
                            orders: filteredSellOrders,
                            type: 'sell',
                            userCurrency: userCurrency,
                          ),

                          SizedBox(height: 20),

                          // Purchases Report
                          _buildTransactionSection(
                            title: 'Purchases Report',
                            orders: filteredBuyOrders,
                            type: 'buy',
                            userCurrency: userCurrency,
                          ),
                        ],
                      ),
                    ),
                  );
                },
          ),
    );
  }

  // Add this new method for quick export buttons
  Widget _buildQuickExportButtons(
    BuildContext context,
    ReportsProvider reportsProvider,
    SellOrderProvider sellProvider,
    BuyOrderProvider buyProvider,
    AuthProvider authProvider,
    String userName,
    String userCurrency,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Export Reports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildExportButton(
                  label: 'Sales PDF',
                  icon: Icons.sell,
                  color: Colors.green,
                  onTap: () => _exportSalesReport(
                    context,
                    reportsProvider,
                    sellProvider,
                    authProvider,
                    userName,
                    userCurrency,
                  ),
                ),
                _buildExportButton(
                  label: 'Purchases PDF',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                  onTap: () => _exportPurchasesReport(
                    context,
                    reportsProvider,
                    buyProvider,
                    authProvider,
                    userName,
                    userCurrency,
                  ),
                ),
                _buildExportButton(
                  label: 'Profit & Loss',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                  onTap: () => _exportProfitLossReport(
                    context,
                    reportsProvider,
                    sellProvider,
                    buyProvider,
                    authProvider,
                    userName,
                    userCurrency,
                  ),
                ),
                _buildExportButton(
                  label: 'Full Report',
                  icon: Icons.assignment,
                  color: Colors.orange,
                  onTap: () => _exportComprehensiveReport(
                    context,
                    reportsProvider,
                    sellProvider,
                    buyProvider,
                    authProvider,
                    userName,
                    userCurrency,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // In your ReportsScreen, update the export method to add debugging:

  Future<void> _exportSalesReport(
    BuildContext context,
    ReportsProvider reportsProvider,
    SellOrderProvider sellProvider,
    AuthProvider authProvider,
    String userName,
    String userCurrency,
  ) async {
    print('=== UI DEBUG: Exporting sales report ===');
    print('Orders count: ${sellProvider.sellOrders.length}');
    print('User name: $userName');
    print('Currency: $userCurrency');

    // Log first few orders to ensure data exists
    if (sellProvider.sellOrders.isNotEmpty) {
      print('Sample order data:');
      for (var i = 0; i < min(3, sellProvider.sellOrders.length); i++) {
        final order = sellProvider.sellOrders[i];
        print(
          '  Order $i: ${order.customerName} - ${order.productName} - ${order.totalAmount}',
        );
      }
    } else {
      print('No orders found!');
    }

    setState(() => _isExporting = true);

    try {
      final filePath = await PdfExportService.exportSalesReport(
        orders: sellProvider.sellOrders,
        userCurrency: userCurrency,
        userName: userName,
        dateRange: reportsProvider.selectedDateRange,
        filter: reportsProvider.selectedFilter,
      );

      await _showExportSuccessDialog(context, filePath);
    } catch (e) {
      print('Export error details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPurchasesReport(
    BuildContext context,
    ReportsProvider reportsProvider,
    BuyOrderProvider buyProvider,
    AuthProvider authProvider,
    String userName,
    String userCurrency,
  ) async {
    setState(() => _isExporting = true);

    try {
      final filePath = await PdfExportService.exportPurchasesReport(
        orders: buyProvider.buyOrders,
        userCurrency: userCurrency,
        userName: userName,
        dateRange: reportsProvider.selectedDateRange,
        filter: reportsProvider.selectedFilter,
      );

      await _showExportSuccessDialog(context, filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export purchases report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportProfitLossReport(
    BuildContext context,
    ReportsProvider reportsProvider,
    SellOrderProvider sellProvider,
    BuyOrderProvider buyProvider,
    AuthProvider authProvider,
    String userName,
    String userCurrency,
  ) async {
    setState(() => _isExporting = true);

    try {
      final filePath = await PdfExportService.exportProfitLossReport(
        sellOrders: sellProvider.sellOrders,
        buyOrders: buyProvider.buyOrders,
        userCurrency: userCurrency,
        userName: userName,
        dateRange: reportsProvider.selectedDateRange,
        filter: reportsProvider.selectedFilter,
      );

      await _showExportSuccessDialog(context, filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export profit & loss report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportComprehensiveReport(
    BuildContext context,
    ReportsProvider reportsProvider,
    SellOrderProvider sellProvider,
    BuyOrderProvider buyProvider,
    AuthProvider authProvider,
    String userName,
    String userCurrency,
  ) async {
    setState(() => _isExporting = true);

    try {
      final totals = reportsProvider.calculateTotals(
        sellOrders: sellProvider.sellOrders,
        buyOrders: buyProvider.buyOrders,
      );

      final filePath = await PdfExportService.exportComprehensiveReport(
        sellOrders: sellProvider.sellOrders,
        buyOrders: buyProvider.buyOrders,
        userCurrency: userCurrency,
        userName: userName,
        totals: totals,
        dateRange: reportsProvider.selectedDateRange,
        filter: reportsProvider.selectedFilter,
      );

      await _showExportSuccessDialog(context, filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export comprehensive report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _showExportSuccessDialog(
    BuildContext context,
    String filePath,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Exported Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF has been saved to:'),
            SizedBox(height: 8),
            Text(
              filePath.split('/').last,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PdfExportService.sharePdf(filePath);
            },
            child: Text('Share'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PdfExportService.openPdf(filePath);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Open'),
          ),
        ],
      ),
    );
  }

  void _handleExportAction(String value, BuildContext context) {
    switch (value) {
      case 'sales':
        _exportSalesReport(
          context,
          Provider.of<ReportsProvider>(context, listen: false),
          Provider.of<SellOrderProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false).userData?['name'] ??
              'User',
          Provider.of<AuthProvider>(
                context,
                listen: false,
              ).userData?['transactionCurrency'] ??
              'USD',
        );
        break;
      case 'purchases':
        _exportPurchasesReport(
          context,
          Provider.of<ReportsProvider>(context, listen: false),
          Provider.of<BuyOrderProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false).userData?['name'] ??
              'User',
          Provider.of<AuthProvider>(
                context,
                listen: false,
              ).userData?['transactionCurrency'] ??
              'USD',
        );
        break;
      case 'profit':
        _exportProfitLossReport(
          context,
          Provider.of<ReportsProvider>(context, listen: false),
          Provider.of<SellOrderProvider>(context, listen: false),
          Provider.of<BuyOrderProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false).userData?['name'] ??
              'User',
          Provider.of<AuthProvider>(
                context,
                listen: false,
              ).userData?['transactionCurrency'] ??
              'USD',
        );
        break;
      case 'comprehensive':
        _exportComprehensiveReport(
          context,
          Provider.of<ReportsProvider>(context, listen: false),
          Provider.of<SellOrderProvider>(context, listen: false),
          Provider.of<BuyOrderProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false),
          Provider.of<AuthProvider>(context, listen: false).userData?['name'] ??
              'User',
          Provider.of<AuthProvider>(
                context,
                listen: false,
              ).userData?['transactionCurrency'] ??
              'USD',
        );
        break;
    }
  }

  Widget _buildFilterControls(
    BuildContext context,
    ReportsProvider reportsProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Range Selector - FIXED LAYOUT
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date Range:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  _selectDateRange(context, reportsProvider),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(
                                reportsProvider.selectedDateRange == null
                                    ? 'All Dates'
                                    : '${_dateFormat.format(reportsProvider.selectedDateRange!.start)} - ${_dateFormat.format(reportsProvider.selectedDateRange!.end)}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (reportsProvider.selectedDateRange != null)
                            IconButton(
                              icon: Icon(Icons.clear, size: 18),
                              onPressed: () {
                                // ignore: null_check_always_fails
                                reportsProvider.setDateRange(null!);
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 15),

            // Type Filter - FIXED LAYOUT
            Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: Text('All'),
                            selected: reportsProvider.selectedFilter == 'all',
                            onSelected: (_) => reportsProvider.setFilter('all'),
                          ),
                          FilterChip(
                            label: Text('Completed'),
                            selected:
                                reportsProvider.selectedFilter == 'completed',
                            onSelected: (_) =>
                                reportsProvider.setFilter('completed'),
                          ),
                          FilterChip(
                            label: Text('Pending'),
                            selected:
                                reportsProvider.selectedFilter == 'pending',
                            onSelected: (_) =>
                                reportsProvider.setFilter('pending'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, double> totals, String userCurrency) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        SummaryCard(
          title: 'Total Sales',
          value: CurrencyHelper.formatAmount(
            totals['sales'] ?? 0,
            userCurrency,
          ),
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        SummaryCard(
          title: 'Total Purchases',
          value: CurrencyHelper.formatAmount(
            totals['purchases'] ?? 0,
            userCurrency,
          ),
          icon: Icons.trending_down,
          color: Colors.orange,
        ),
        SummaryCard(
          title: 'Gross Profit',
          value: CurrencyHelper.formatAmount(
            totals['profit'] ?? 0,
            userCurrency,
          ),
          icon: Icons.account_balance_wallet,
          color: totals['profit']! >= 0 ? Colors.blue : Colors.red,
        ),
        SummaryCard(
          title: 'Profit Margin',
          value: totals['sales']! > 0
              ? '${((totals['profit']! / totals['sales']!) * 100).toStringAsFixed(1)}%'
              : '0%',
          icon: Icons.percent,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTransactionSection({
    required String title,
    required List orders,
    required String type,
    required String userCurrency,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'sell' ? Icons.sell : Icons.shopping_cart,
                  color: Colors.blue,
                ),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Chip(
                  label: Text('${orders.length} transactions'),
                  backgroundColor: Colors.blue[50],
                ),
              ],
            ),

            SizedBox(height: 15),

            if (orders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No ${type == 'sell' ? 'sales' : 'purchases'} found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...orders
                  .take(5)
                  .map(
                    (order) => _buildTransactionItem(order, type, userCurrency),
                  ),

            if (orders.length > 5)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    '... and ${orders.length - 5} more transactions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    dynamic order,
    String type,
    String userCurrency,
  ) {
    final isSell = type == 'sell';
    final name = isSell ? order.customerName : order.supplierName;
    final status = order.isCompleted ? 'Completed' : 'Pending';
    final date = _dateFormat.format(order.date);
    final amount = order.totalAmount;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Icon
          Container(
            margin: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: order.isCompleted
                  ? Colors.green[100]
                  : Colors.orange[100],
              radius: 18,
              child: Icon(
                isSell ? Icons.sell : Icons.shopping_cart,
                size: 16,
                color: order.isCompleted ? Colors.green : Colors.orange,
              ),
            ),
          ),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 4),

                // Status and Date Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.isCompleted ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount - Moved to separate row for better layout
          Container(
            margin: EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyHelper.formatAmount(amount, userCurrency),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSell ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  isSell ? 'Sale' : 'Purchase',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    ReportsProvider reportsProvider,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      currentDate: DateTime.now(),
      initialDateRange:
          reportsProvider.selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 30)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      reportsProvider.setDateRange(picked);
    }
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
