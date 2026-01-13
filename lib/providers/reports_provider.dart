// File: lib/providers/reports_provider.dart
import 'package:flutter/material.dart';
import '../models/sell_order_model.dart';
import '../models/buy_order_model.dart';

class ReportsProvider with ChangeNotifier {
  DateTimeRange? _selectedDateRange;
  String _selectedFilter = 'all'; // 'all', 'sell', 'buy'

  DateTimeRange? get selectedDateRange => _selectedDateRange;
  String get selectedFilter => _selectedFilter;

  void setDateRange(DateTimeRange range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // Calculate profit/loss
  double calculateProfit({
    required List<SellOrder> sellOrders,
    required List<BuyOrder> buyOrders,
  }) {
    // Total revenue from completed sell orders (paid & delivered)
    double totalRevenue = sellOrders
        .where((order) => order.isCompleted && order.paymentReceived)
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    // Total cost from completed buy orders (paid)
    double totalCost = buyOrders
        .where((order) => order.isCompleted && order.paid)
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    return totalRevenue - totalCost;
  }

  // Get filtered sell orders
  List<SellOrder> getFilteredSellOrders(List<SellOrder> allOrders) {
    List<SellOrder> filtered = allOrders;

    // Apply date filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((order) {
        return order.date.isAfter(
              _selectedDateRange!.start.subtract(Duration(days: 1)),
            ) &&
            order.date.isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter == 'completed') {
      filtered = filtered.where((order) => order.isCompleted).toList();
    } else if (_selectedFilter == 'pending') {
      filtered = filtered.where((order) => order.isPending).toList();
    }

    return filtered;
  }

  // Get filtered buy orders
  List<BuyOrder> getFilteredBuyOrders(List<BuyOrder> allOrders) {
    List<BuyOrder> filtered = allOrders;

    // Apply date filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((order) {
        return order.date.isAfter(
              _selectedDateRange!.start.subtract(Duration(days: 1)),
            ) &&
            order.date.isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter == 'completed') {
      filtered = filtered.where((order) => order.isCompleted).toList();
    } else if (_selectedFilter == 'pending') {
      filtered = filtered.where((order) => order.isPending).toList();
    }

    return filtered;
  }

  // Calculate totals for display
  Map<String, double> calculateTotals({
    required List<SellOrder> sellOrders,
    required List<BuyOrder> buyOrders,
  }) {
    double totalSales = sellOrders
        .where((order) => order.isCompleted && order.paymentReceived)
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    double totalPurchases = buyOrders
        .where((order) => order.isCompleted && order.paid)
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    double profitLoss = totalSales - totalPurchases;

    return {
      'sales': totalSales,
      'purchases': totalPurchases,
      'profit': profitLoss,
    };
  }
}
