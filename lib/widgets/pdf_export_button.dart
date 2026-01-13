// File: lib/widgets/pdf_export_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sell_order_provider.dart';
import '../providers/buy_order_provider.dart';
import '../services/pdf_export_service.dart';

class PdfExportButton extends StatefulWidget {
  final ExportType exportType;
  final DateTimeRange? dateRange;
  final String filter;

  const PdfExportButton({
    super.key,
    required this.exportType,
    this.dateRange,
    this.filter = 'all',
  });

  @override
  State<PdfExportButton> createState() => _PdfExportButtonState();
}

enum ExportType { sales, purchases, profitLoss, comprehensive }

class _PdfExportButtonState extends State<PdfExportButton> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return _isExporting
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _handleExport,
            tooltip: 'Export to PDF',
          );
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userName = authProvider.userData?['name'] ?? 'User';
      final userCurrency =
          authProvider.userData?['transactionCurrency'] ?? 'USD';

      String filePath;
      String reportName;

      switch (widget.exportType) {
        case ExportType.sales:
          final sellProvider = Provider.of<SellOrderProvider>(
            context,
            listen: false,
          );
          filePath = await PdfExportService.exportSalesReport(
            orders: sellProvider.sellOrders,
            userCurrency: userCurrency,
            userName: userName,
            dateRange: widget.dateRange,
            filter: widget.filter,
          );
          reportName = 'Sales Report';
          break;

        case ExportType.purchases:
          final buyProvider = Provider.of<BuyOrderProvider>(
            context,
            listen: false,
          );
          filePath = await PdfExportService.exportPurchasesReport(
            orders: buyProvider.buyOrders,
            userCurrency: userCurrency,
            userName: userName,
            dateRange: widget.dateRange,
            filter: widget.filter,
          );
          reportName = 'Purchases Report';
          break;

        case ExportType.profitLoss:
          final sellProvider = Provider.of<SellOrderProvider>(
            context,
            listen: false,
          );
          final buyProvider = Provider.of<BuyOrderProvider>(
            context,
            listen: false,
          );
          filePath = await PdfExportService.exportProfitLossReport(
            sellOrders: sellProvider.sellOrders,
            buyOrders: buyProvider.buyOrders,
            userCurrency: userCurrency,
            userName: userName,
            dateRange: widget.dateRange,
            filter: widget.filter,
          );
          reportName = 'Profit & Loss Report';
          break;

        case ExportType.comprehensive:
          final sellProvider = Provider.of<SellOrderProvider>(
            context,
            listen: false,
          );
          final buyProvider = Provider.of<BuyOrderProvider>(
            context,
            listen: false,
          );
          filePath = await PdfExportService.exportComprehensiveReport(
            sellOrders: sellProvider.sellOrders,
            buyOrders: buyProvider.buyOrders,
            userCurrency: userCurrency,
            userName: userName,
            totals: {}, // You might want to calculate totals here
            dateRange: widget.dateRange,
            filter: widget.filter,
          );
          reportName = 'Comprehensive Report';
          break;
      }

      // Show success dialog
      await _showSuccessDialog(context, filePath, reportName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _showSuccessDialog(
    BuildContext context,
    String filePath,
    String reportName,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$reportName Exported'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF has been saved successfully.'),
            SizedBox(height: 8),
            Text(
              'File: ${filePath.split('/').last}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
        ],
      ),
    );
  }
}
