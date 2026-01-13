// File: lib/utils/currency_helper.dart
class CurrencyHelper {
  static String getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'AED':
        return 'د.إ';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      case 'CHF':
        return 'CHF';
      case 'SGD':
        return 'S\$';
      case 'MYR':
        return 'RM';
      case 'THB':
        return '฿';
      case 'IDR':
        return 'Rp';
      case 'PHP':
        return '₱';
      case 'KRW':
        return '₩';
      case 'VND':
        return '₫';
      default:
        return currencyCode;
    }
  }

  static String formatAmount(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatWithCode(double amount, String currencyCode) {
    return '${amount.toStringAsFixed(2)} $currencyCode';
  }

  // NEW: Format conversion rate display
  static String formatConversionRate({
    required double rate,
    required String fromCurrency,
    required String toCurrency,
    bool invert = false,
  }) {
    if (rate == 0) return 'N/A';

    if (invert) {
      // Show reciprocal rate (e.g., 1 AED = X INR)
      final reciprocalRate = 1 / rate;
      return '1 $toCurrency = ${reciprocalRate.toStringAsFixed(3)} $fromCurrency';
    } else {
      // Show direct rate (e.g., 1 INR = X AED)
      return '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency';
    }
  }

  // NEW: Calculate converted amount
  static double convertAmount({
    required double amount,
    required double rate,
    required String fromCurrency,
    required String toCurrency,
  }) {
    return amount * rate;
  }

  // NEW: Get reciprocal rate
  static double getReciprocalRate(double rate) {
    return rate != 0 ? 1 / rate : 0;
  }

  // NEW: Format rate with both currencies
  static String formatRateDisplay({
    required double rate,
    required String productCurrency,
    required String userCurrency,
    bool showReciprocal = false,
  }) {
    if (rate == 0) return 'N/A';

    if (showReciprocal) {
      final reciprocalRate = 1 / rate;
      return '${reciprocalRate.toStringAsFixed(2)} $productCurrency/$userCurrency';
    } else {
      return '${rate.toStringAsFixed(4)} $userCurrency/$productCurrency';
    }
  }
}
