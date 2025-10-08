import 'package:intl/intl.dart';

class AppFormater {
  static String formatAmount(double amount, {bool withDecimal = false}) {
    final formatter = NumberFormat.currency(
        locale: 'en_NG', symbol: '', decimalDigits: withDecimal ? 2 : 0); // ₦

    return formatter.format(amount);
  }
}
