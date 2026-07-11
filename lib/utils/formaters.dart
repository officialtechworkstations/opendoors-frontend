import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppFormater {
  static String formatAmount(double amount, {bool withDecimal = false}) {
    final formatter = NumberFormat.currency(
        locale: 'en_NG', symbol: '', decimalDigits: withDecimal ? 2 : 0); // ₦

    return formatter.format(amount);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final bool withDecimal;

  CurrencyInputFormatter({this.withDecimal = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return newValue.copyWith(text: '');

    double value =
        withDecimal ? double.parse(digits) / 100 : double.parse(digits);

    String formatted =
        AppFormater.formatAmount(value, withDecimal: withDecimal);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String formatAsCurrency(String value) {
    if (value.isEmpty) return '';

    // Remove existing commas
    String cleanValue = value.replaceAll(',', '');

    if (cleanValue.isEmpty) return '';

    // Format with commas
    final number = int.parse(cleanValue);
    return NumberFormat('#,##0').format(number);
  }
}
