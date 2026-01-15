// File: lib/screens/reports_screen.dart - BLUE THEME COLOR FIXES ONLY
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
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Reports'),
        actions: [
          // Export Button
          PopupMenuButton<String>(
            onSelected: (value) => _handleExportAction(value, context),
            color: const Color(
              0xFFF0F8FF,
            ), // Light blue background for dropdown
            surfaceTintColor: const Color(
              0xFFE3F2FD,
            ), // Material 3 surface tint
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(
                color: Color(0xFFBBDEFB), // Light blue border
                width: 1,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'sales',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFF388E3C), // Green
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Export Sales Report',
                      style: TextStyle(
                        color: Color(0xFF0D47A1), // Dark blue text
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'purchases',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFF1976D2), // Blue
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Export Purchases Report',
                      style: TextStyle(
                        color: Color(0xFF0D47A1), // Dark blue text
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'profit',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFF7B1FA2), // Purple
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Export Profit & Loss Report',
                      style: TextStyle(
                        color: Color(0xFF0D47A1), // Dark blue text
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'comprehensive',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFFF57C00), // Orange
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Export Comprehensive Report',
                      style: TextStyle(
                        color: Color(0xFF0D47A1), // Dark blue text
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            icon: _isExporting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white, // White progress indicator
                      ),
                    ),
                  )
                : Icon(Icons.picture_as_pdf, color: Colors.white),
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
      color: const Color(0xFFE3F2FD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFBBDEFB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // REDUCED from 16.0 to 12.0
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Color(0xFF1976D2),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Export Reports',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10), // REDUCED from 12 to 8
            // Button Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio:
                  3.0, // CHANGED from 2.8 to 3.2 (wider, less tall)
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                // Sales Report Button
                _buildSimpleExportButton(
                  title: 'Sales',
                  subtitle: 'Transactions',
                  icon: Icons.sell,
                  color: const Color(0xFF388E3C),
                  onTap: () => _exportSalesReport(
                    context,
                    reportsProvider,
                    sellProvider,
                    authProvider,
                    userName,
                    userCurrency,
                  ),
                ),

                // Purchases Report Button
                _buildSimpleExportButton(
                  title: 'Purchases',
                  subtitle: 'Orders',
                  icon: Icons.shopping_cart,
                  color: const Color(0xFF1976D2),
                  onTap: () => _exportPurchasesReport(
                    context,
                    reportsProvider,
                    buyProvider,
                    authProvider,
                    userName,
                    userCurrency,
                  ),
                ),
                // Full Report Button
                _buildSimpleExportButton(
                  title: 'Full Report',
                  subtitle: 'Complete',
                  icon: Icons.summarize,
                  color: const Color(0xFFF57C00),
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
                // Profit & Loss Button
                _buildSimpleExportButton(
                  title: 'Profit/Loss',
                  subtitle: 'Analysis',
                  icon: Icons.attach_money,
                  color: const Color(0xFF7B1FA2),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleExportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ), // REDUCED
          child: Row(
            children: [
              // Smaller icon
              Container(
                width: 35, // REDUCED
                height: 35, // REDUCED
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 18),
                ), // Smaller icon
              ),

              // Title and subtitle after icon
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15, // Slightly smaller text
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D47A1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1), // Reduced spacing
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Color.fromARGB(255, 21, 10, 114),
                      ), // Smaller
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          backgroundColor: Color(0xFFD32F2F), // Red
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
          backgroundColor: Color(0xFFD32F2F), // Red
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
          backgroundColor: Color(0xFFD32F2F), // Red
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
          backgroundColor: Color(0xFFD32F2F), // Red
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
        backgroundColor: Colors.white,
        title: Text(
          'Report Exported Successfully',
          style: TextStyle(color: Color(0xFF1565C0)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF has been saved to:',
              style: TextStyle(color: Color(0xFF1976D2)),
            ),
            SizedBox(height: 8),
            Text(
              filePath.split('/').last,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1976D2), // Blue
            ),
            child: Text('Share'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PdfExportService.openPdf(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1976D2), // Blue
            ),
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
      color: const Color(0xFFE3F2FD), // Light blue background
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFBBDEFB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Section - Compact Design
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF1976D2),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date Range',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reportsProvider.selectedDateRange == null
                            ? 'All Dates'
                            : '${_dateFormat.format(reportsProvider.selectedDateRange!.start)} - ${_dateFormat.format(reportsProvider.selectedDateRange!.end)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D47A1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _selectDateRange(context, reportsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: Size(0, 0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 14),
                      SizedBox(width: 4),
                      Text('Select', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Filter Section - Compact Design
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Color(0xFF1976D2),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Equal Size Filter Buttons
                      Row(
                        children: [
                          // All Button
                          Expanded(
                            child: _buildStatusFilterButton(
                              isSelected:
                                  reportsProvider.selectedFilter == 'all',
                              label: 'All',
                              icon: Icons.all_inclusive,
                              color: const Color(0xFF1976D2),
                              onTap: () => reportsProvider.setFilter('all'),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Completed Button
                          Expanded(
                            child: _buildStatusFilterButton(
                              isSelected:
                                  reportsProvider.selectedFilter == 'completed',
                              label: 'Completed',
                              icon: Icons.check_circle,
                              color: const Color(0xFF388E3C),
                              onTap: () =>
                                  reportsProvider.setFilter('completed'),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Pending Button
                          Expanded(
                            child: _buildStatusFilterButton(
                              isSelected:
                                  reportsProvider.selectedFilter == 'pending',
                              label: 'Pending',
                              icon: Icons.pending,
                              color: const Color(0xFFF57C00),
                              onTap: () => reportsProvider.setFilter('pending'),
                            ),
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

  // Helper method to create consistent filter buttons
  Widget _buildStatusFilterButton({
    required bool isSelected,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36, // Fixed height for all buttons
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : color,
              ),
              overflow: TextOverflow.ellipsis,
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
      childAspectRatio: 1.25,
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      children: [
        SummaryCard(
          title: 'Total Sales',
          value: CurrencyHelper.formatAmount(
            totals['sales'] ?? 0,
            userCurrency,
          ),
          icon: Icons.trending_up,
          color: Color(0xFF388E3C), // Green
        ),
        SummaryCard(
          title: 'Total Purchases',
          value: CurrencyHelper.formatAmount(
            totals['purchases'] ?? 0,
            userCurrency,
          ),
          icon: Icons.trending_down,
          color: Color(0xFF1976D2), // Blue
        ),
        SummaryCard(
          title: 'Gross Profit',
          value: CurrencyHelper.formatAmount(
            totals['profit'] ?? 0,
            userCurrency,
          ),
          icon: Icons.account_balance_wallet,
          color: totals['profit']! >= 0
              ? Color(0xFF388E3C) // Green for profit
              : Color(0xFFD32F2F), // Red for loss
        ),
        SummaryCard(
          title: 'Profit Margin',
          value: totals['sales']! > 0
              ? '${((totals['profit']! / totals['sales']!) * 100).toStringAsFixed(1)}%'
              : '0%',
          icon: Icons.percent,
          color: Color(0xFF7B1FA2), // Purple
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
      color: Color(0xFFE3F2FD), // Light blue background
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFFBBDEFB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'sell' ? Icons.sell : Icons.shopping_cart,
                  color: type == 'sell'
                      ? Color(0xFF388E3C) // Green for sales
                      : Color(0xFF1976D2), // Blue for purchases
                ),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF1976D2), width: 1),
                  ),
                  child: Text(
                    '${orders.length} transactions',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
        color: Color(0xFFF0F8FF), // Very light blue
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFBBDEFB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Icon
          Container(
            margin: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: order.isCompleted
                  ? Color(0xFFE8F5E9) // Light green
                  : Color(0xFFFFF3E0), // Light orange
              radius: 18,
              child: Icon(
                isSell ? Icons.sell : Icons.shopping_cart,
                size: 16,
                color: order.isCompleted
                    ? Color(0xFF388E3C) // Green
                    : Color(0xFFF57C00), // Orange
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
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF0D47A1),
                  ),
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
                        color: order.isCompleted
                            ? Color(0xFF388E3C) // Green
                            : Color(0xFFF57C00), // Orange
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
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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
                    color: isSell
                        ? Color(0xFF388E3C) // Green for sales
                        : Color(0xFF1976D2), // Blue for purchases
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  isSell ? 'Sale' : 'Purchase',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
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
      color: Color(0xFFE3F2FD), // Light blue background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFFBBDEFB), width: 1),
      ),
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
              style: TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
