import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    int? value = int.tryParse(newText);
    if (value == null) return newValue.copyWith(text: '');

    final formatter = NumberFormat('#,###', 'es_CL');
    String newString = formatter.format(value);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class AppFormatters {
  static NumberFormat get currency => NumberFormat.currency(
    locale: 'es_CL', 
    symbol: '\$', 
    decimalDigits: 0,
    customPattern: '\$ #,###'
  );
}
