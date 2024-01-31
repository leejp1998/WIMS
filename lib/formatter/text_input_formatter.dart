import 'package:flutter/services.dart';

class CapitalizeWordsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isNotEmpty) {
      // Capitalize the first letter of each word
      String newText = newValue.text.replaceAllMapped(
        RegExp(r'\b\w'),
            (match) => match.group(0)!.toUpperCase(),
      );

      // Ensure that the first letter is always capitalized
      newText = newText.replaceFirst(RegExp(r'\b\w'), newText[0].toUpperCase());

      return newValue.copyWith(text: newText);
    }

    return newValue;
  }
}