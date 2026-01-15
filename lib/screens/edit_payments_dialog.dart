// lib/screens/edit_payments_dialog.dart
import 'package:currency_trading_app/screens/payment_history_buy_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../models/buy_order_model.dart';

class EditPaymentsDialog extends StatelessWidget {
  final BuyOrder order;
  final String userCurrency;

  const EditPaymentsDialog({
    super.key,
    required this.order,
    required this.userCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BuyOrderProvider>(context, listen: false);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // List payments with edit/delete options
            // ... similar to PaymentHistoryBuyDialog but simplified
            ElevatedButton(
              onPressed: () async {
                // Open detailed payment history dialog
                await showDialog(
                  context: context,
                  builder: (context) => PaymentHistoryBuyDialog(
                    order: order,
                    userCurrency: userCurrency,
                  ),
                );
                Navigator.pop(context, true);
              },
              child: Text('Open Payment Manager'),
            ),
          ],
        ),
      ),
    );
  }
}
