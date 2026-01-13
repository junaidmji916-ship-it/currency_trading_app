// File: lib/services/pdf_export_service.dart - FINAL WORKING VERSION
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/sell_order_model.dart';
import '../models/buy_order_model.dart';
import '../utils/currency_helper.dart';

class PdfExportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Export sales report
  static Future<String> exportSalesReport({
    required List<SellOrder> orders,
    required String userCurrency,
    required String userName,
    DateTimeRange? dateRange,
    String filter = 'all',
  }) async {
    print('=== PDF DEBUG: Starting sales report export ===');

    try {
      final pdf = pw.Document();
      final filteredOrders = _filterOrders(orders, dateRange, filter);

      print(
        '=== PDF DEBUG: Filtered orders count: ${filteredOrders.length} ===',
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Simple header only
              _buildSimpleHeader(
                title: 'Sales Report',
                userName: userName,
                startDate: dateRange?.start,
                endDate: dateRange?.end,
                transactionCount: filteredOrders.length,
              ),

              pw.SizedBox(height: 20),

              // Add basic summary
              _buildBasicSalesSummary(filteredOrders, userCurrency),

              pw.SizedBox(height: 20),

              // Add simple orders list
              _buildSimpleOrdersList(filteredOrders, userCurrency, 'sell'),
            ];
          },
        ),
      );

      return await _saveAndSharePdf(
        pdf,
        'sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stackTrace) {
      print('=== PDF DEBUG: ERROR in exportSalesReport ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Export purchases report
  static Future<String> exportPurchasesReport({
    required List<BuyOrder> orders,
    required String userCurrency,
    required String userName,
    DateTimeRange? dateRange,
    String filter = 'all',
  }) async {
    print('=== PDF DEBUG: Starting purchases report export ===');

    try {
      final pdf = pw.Document();
      final filteredOrders = _filterOrders(orders, dateRange, filter);

      print(
        '=== PDF DEBUG: Filtered orders count: ${filteredOrders.length} ===',
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Simple header only
              _buildSimpleHeader(
                title: 'Purchases Report',
                userName: userName,
                startDate: dateRange?.start,
                endDate: dateRange?.end,
                transactionCount: filteredOrders.length,
              ),

              pw.SizedBox(height: 20),

              // Add basic summary
              _buildBasicPurchasesSummary(filteredOrders, userCurrency),

              pw.SizedBox(height: 20),

              // Add simple orders list
              _buildSimpleOrdersList(filteredOrders, userCurrency, 'buy'),
            ];
          },
        ),
      );

      return await _saveAndSharePdf(
        pdf,
        'purchases_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stackTrace) {
      print('=== PDF DEBUG: ERROR in exportPurchasesReport ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Export profit & loss report
  static Future<String> exportProfitLossReport({
    required List<SellOrder> sellOrders,
    required List<BuyOrder> buyOrders,
    required String userCurrency,
    required String userName,
    DateTimeRange? dateRange,
    String filter = 'all',
  }) async {
    print('=== PDF DEBUG: Starting profit & loss report export ===');

    try {
      final pdf = pw.Document();
      final filteredSellOrders = _filterOrders(sellOrders, dateRange, filter);
      final filteredBuyOrders = _filterOrders(buyOrders, dateRange, filter);

      print(
        '=== PDF DEBUG: Filtered sell orders: ${filteredSellOrders.length} ===',
      );
      print(
        '=== PDF DEBUG: Filtered buy orders: ${filteredBuyOrders.length} ===',
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Simple header
              _buildSimpleHeader(
                title: 'Profit & Loss Report',
                userName: userName,
                startDate: dateRange?.start,
                endDate: dateRange?.end,
                transactionCount:
                    filteredSellOrders.length + filteredBuyOrders.length,
              ),

              pw.SizedBox(height: 20),

              // Profit & Loss Summary
              _buildProfitLossSummary(
                filteredSellOrders,
                filteredBuyOrders,
                userCurrency,
              ),

              pw.SizedBox(height: 20),

              // Sales Section
              pw.Text(
                'Sales',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildBasicSalesSummary(filteredSellOrders, userCurrency),

              pw.SizedBox(height: 20),

              // Purchases Section
              pw.Text(
                'Purchases',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildBasicPurchasesSummary(filteredBuyOrders, userCurrency),
            ];
          },
        ),
      );

      return await _saveAndSharePdf(
        pdf,
        'profit_loss_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stackTrace) {
      print('=== PDF DEBUG: ERROR in exportProfitLossReport ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Export comprehensive report - WORKING VERSION
  static Future<String> exportComprehensiveReport({
    required List<SellOrder> sellOrders,
    required List<BuyOrder> buyOrders,
    required String userCurrency,
    required String userName,
    required Map<String, double> totals,
    DateTimeRange? dateRange,
    String filter = 'all',
  }) async {
    print('=== PDF DEBUG: Starting comprehensive report export ===');

    try {
      final pdf = pw.Document();
      final filteredSellOrders = _filterOrders(sellOrders, dateRange, filter);
      final filteredBuyOrders = _filterOrders(buyOrders, dateRange, filter);

      // Ensure totals has required values
      final safeTotals = {
        'sales': totals['sales'] ?? 0.0,
        'purchases': totals['purchases'] ?? 0.0,
        'profit': totals['profit'] ?? 0.0,
      };

      // PAGE 1: Executive Summary
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildSimpleHeader(
                  title: 'Comprehensive Trading Report',
                  userName: userName,
                  startDate: dateRange?.start,
                  endDate: dateRange?.end,
                  transactionCount:
                      filteredSellOrders.length + filteredBuyOrders.length,
                ),
                pw.SizedBox(height: 20),
                // Executive Summary
                _buildExecutiveSummary(safeTotals, userCurrency),
                pw.SizedBox(height: 20),
                // Simple Key Metrics
                _buildSimpleKeyMetrics(
                  filteredSellOrders,
                  filteredBuyOrders,
                  userCurrency,
                ),
              ],
            );
          },
        ),
      );

      // PAGE 2: Sales Summary (if exists)
      if (filteredSellOrders.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Sales Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildBasicSalesSummary(filteredSellOrders, userCurrency),
                  pw.SizedBox(height: 20),
                  // Show only top 5 sales orders
                  _buildLimitedOrdersList(
                    filteredSellOrders,
                    userCurrency,
                    'sell',
                    limit: 5,
                  ),
                ],
              );
            },
          ),
        );
      }

      // PAGE 3: Purchases Summary (if exists)
      if (filteredBuyOrders.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Purchases Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildBasicPurchasesSummary(filteredBuyOrders, userCurrency),
                  pw.SizedBox(height: 20),
                  // Show only top 5 purchase orders
                  _buildLimitedOrdersList(
                    filteredBuyOrders,
                    userCurrency,
                    'buy',
                    limit: 5,
                  ),
                ],
              );
            },
          ),
        );
      }

      return await _saveAndSharePdf(
        pdf,
        'comprehensive_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stackTrace) {
      print('=== PDF DEBUG: ERROR in exportComprehensiveReport ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Simple header
  static pw.Widget _buildSimpleHeader({
    required String title,
    required String userName,
    required DateTime? startDate,
    required DateTime? endDate,
    required int transactionCount,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Currency Trading App',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),

        pw.SizedBox(height: 5),

        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 15),

        pw.Divider(thickness: 2),

        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Generated By: ${userName.isNotEmpty ? userName : "User"}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Date: ${_dateTimeFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Transactions: $transactionCount',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Basic sales summary
  static pw.Widget _buildBasicSalesSummary(
    List<SellOrder> orders,
    String userCurrency,
  ) {
    // Calculate simple totals
    double totalAmount = 0;
    int completedCount = 0;
    int pendingCount = 0;

    for (final order in orders) {
      totalAmount += order.totalAmount;
      if (order.isCompleted) {
        completedCount++;
      } else {
        pendingCount++;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sales Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green,
          ),
        ),

        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSimpleMetricItem(
              'Total Amount',
              CurrencyHelper.formatAmount(totalAmount, userCurrency),
              PdfColors.green,
            ),
            _buildSimpleMetricItem(
              'Completed',
              '$completedCount orders',
              PdfColors.blue,
            ),
            _buildSimpleMetricItem(
              'Pending',
              '$pendingCount orders',
              PdfColors.orange,
            ),
          ],
        ),
      ],
    );
  }

  // Basic purchases summary
  static pw.Widget _buildBasicPurchasesSummary(
    List<BuyOrder> orders,
    String userCurrency,
  ) {
    // Calculate simple totals
    double totalAmount = 0;
    int completedCount = 0;
    int pendingCount = 0;

    for (final order in orders) {
      totalAmount += order.totalAmount;
      if (order.isCompleted) {
        completedCount++;
      } else {
        pendingCount++;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Purchases Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),

        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSimpleMetricItem(
              'Total Amount',
              CurrencyHelper.formatAmount(totalAmount, userCurrency),
              PdfColors.blue,
            ),
            _buildSimpleMetricItem(
              'Completed',
              '$completedCount orders',
              PdfColors.green,
            ),
            _buildSimpleMetricItem(
              'Pending',
              '$pendingCount orders',
              PdfColors.orange,
            ),
          ],
        ),
      ],
    );
  }

  // Profit & Loss summary
  static pw.Widget _buildProfitLossSummary(
    List<SellOrder> sellOrders,
    List<BuyOrder> buyOrders,
    String userCurrency,
  ) {
    // Calculate sales total
    double salesTotal = 0;
    for (final order in sellOrders) {
      if (order.isCompleted && order.paymentReceived) {
        salesTotal += order.totalAmount;
      }
    }

    // Calculate purchases total
    double purchasesTotal = 0;
    for (final order in buyOrders) {
      if (order.isCompleted && order.paid) {
        purchasesTotal += order.totalAmount;
      }
    }

    final profit = salesTotal - purchasesTotal;
    final margin = salesTotal > 0 ? (profit / salesTotal * 100) : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Profit & Loss Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.purple,
          ),
        ),

        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSimpleMetricItem(
              'Total Revenue',
              CurrencyHelper.formatAmount(salesTotal, userCurrency),
              PdfColors.green,
            ),
            _buildSimpleMetricItem(
              'Total Cost',
              CurrencyHelper.formatAmount(purchasesTotal, userCurrency),
              PdfColors.blue,
            ),
            _buildSimpleMetricItem(
              'Net Profit',
              CurrencyHelper.formatAmount(profit, userCurrency),
              profit >= 0 ? PdfColors.green : PdfColors.red,
            ),
            _buildSimpleMetricItem(
              'Profit Margin',
              '${margin.toStringAsFixed(1)}%',
              margin >= 0 ? PdfColors.purple : PdfColors.red,
            ),
          ],
        ),
      ],
    );
  }

  // Executive Summary
  static pw.Widget _buildExecutiveSummary(
    Map<String, double> totals,
    String userCurrency,
  ) {
    final sales = totals['sales'] ?? 0.0;
    final purchases = totals['purchases'] ?? 0.0;
    final profit = totals['profit'] ?? 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Executive Summary',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),

        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSimpleMetricItem(
              'Total Sales',
              CurrencyHelper.formatAmount(sales, userCurrency),
              PdfColors.green,
            ),
            _buildSimpleMetricItem(
              'Total Purchases',
              CurrencyHelper.formatAmount(purchases, userCurrency),
              PdfColors.blue,
            ),
            _buildSimpleMetricItem(
              'Net Profit',
              CurrencyHelper.formatAmount(profit, userCurrency),
              profit >= 0 ? PdfColors.green : PdfColors.red,
            ),
          ],
        ),

        pw.SizedBox(height: 15),

        pw.Center(
          child: pw.Text(
            profit >= 0 ? '✅ Profitable Performance' : '⚠️ Operating at a Loss',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: profit >= 0 ? PdfColors.green : PdfColors.red,
            ),
          ),
        ),
      ],
    );
  }

  // Simple Key Metrics (for comprehensive report)
  static pw.Widget _buildSimpleKeyMetrics(
    List<SellOrder> sellOrders,
    List<BuyOrder> buyOrders,
    String userCurrency,
  ) {
    final totalOrders = sellOrders.length + buyOrders.length;
    final completedOrders =
        sellOrders.where((o) => o.isCompleted).length +
        buyOrders.where((o) => o.isCompleted).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Key Metrics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildSimpleMetricItem(
              'Total Orders',
              '$totalOrders',
              PdfColors.blue,
            ),
            _buildSimpleMetricItem(
              'Completed',
              '$completedOrders',
              PdfColors.green,
            ),
          ],
        ),
      ],
    );
  }

  // Original Key Metrics (keep for other reports if needed)

  static pw.Widget _buildSimpleMetricItem(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Simple orders list for regular reports
  static pw.Widget _buildSimpleOrdersList(
    List orders,
    String userCurrency,
    String type,
  ) {
    if (orders.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No ${type == 'sell' ? 'sales' : 'purchases'} orders found',
        ),
      );
    }

    final isSell = type == 'sell';
    final maxOrders = 10;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent ${isSell ? 'Sales' : 'Purchases'}',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),

        // Show limited orders
        ...orders.take(maxOrders).map((order) {
          final name = isSell ? order.customerName : order.supplierName;
          final productLabel = isSell ? 'Product' : 'Item';

          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: 8),
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      name,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      CurrencyHelper.formatAmount(
                        order.totalAmount,
                        userCurrency,
                      ),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: isSell ? PdfColors.green : PdfColors.blue,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 5),

                pw.Text(
                  '$productLabel: ${order.productName} (${order.productCode})',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),

                pw.SizedBox(height: 5),

                pw.Row(
                  children: [
                    pw.Text(
                      'Date: ${_dateFormat.format(order.date)}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      'Status: ${order.isCompleted ? "Completed" : "Pending"}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: order.isCompleted
                            ? PdfColors.green
                            : PdfColors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        if (orders.length > maxOrders)
          pw.Center(
            child: pw.Text(
              '... and ${orders.length - maxOrders} more orders',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
          ),
      ],
    );
  }

  // Limited orders list for comprehensive report
  static pw.Widget _buildLimitedOrdersList(
    List orders,
    String userCurrency,
    String type, {
    int limit = 5,
  }) {
    if (orders.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No ${type == 'sell' ? 'sales' : 'purchases'} orders found',
        ),
      );
    }

    final isSell = type == 'sell';
    final limitedOrders = orders.take(limit).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top $limit ${isSell ? 'Sales' : 'Purchases'}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...limitedOrders.map((order) {
          final name = isSell ? order.customerName : order.supplierName;

          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: 8),
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      name,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${order.productCode}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  CurrencyHelper.formatAmount(order.totalAmount, userCurrency),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: isSell ? PdfColors.green : PdfColors.blue,
                  ),
                ),
              ],
            ),
          );
        }),

        if (orders.length > limit)
          pw.Center(
            child: pw.Text(
              '... and ${orders.length - limit} more orders',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ),
      ],
    );
  }

  // Helper methods
  static List<T> _filterOrders<T>(
    List<T> orders,
    DateTimeRange? dateRange,
    String filter,
  ) {
    List<T> filtered = orders;

    if (dateRange != null) {
      filtered = filtered.where((order) {
        final date = _getOrderDate(order);
        return date.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
            date.isBefore(dateRange.end.add(Duration(days: 1)));
      }).toList();
    }

    if (filter == 'completed') {
      filtered = filtered.where((order) => _isOrderCompleted(order)).toList();
    } else if (filter == 'pending') {
      filtered = filtered.where((order) => !_isOrderCompleted(order)).toList();
    }

    return filtered;
  }

  static DateTime _getOrderDate(dynamic order) {
    if (order is SellOrder) return order.date;
    if (order is BuyOrder) return order.date;
    return DateTime.now();
  }

  static bool _isOrderCompleted(dynamic order) {
    if (order is SellOrder) return order.isCompleted;
    if (order is BuyOrder) return order.isCompleted;
    return false;
  }

  // Save and share PDF
  static Future<String> _saveAndSharePdf(
    pw.Document pdf,
    String fileName,
  ) async {
    try {
      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Save PDF
      final File file = File(filePath);
      final Uint8List bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      print('=== PDF DEBUG: PDF saved successfully: $filePath ===');
      return filePath;
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  // Share PDF file
  static Future<void> sharePdf(String filePath) async {
    try {
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Currency Trading Report');
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }

  // Open PDF file
  static Future<void> openPdf(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      print('Error opening PDF: $e');
      rethrow;
    }
  }
}
