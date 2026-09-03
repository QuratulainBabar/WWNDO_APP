import 'package:flutter/services.dart';

/// Keeps spaces (and optionally a leading `+`) but stops extra digits
/// once [maxDigits] is reached.
class PhoneDigitLimiter extends TextInputFormatter {
  const PhoneDigitLimiter(this.maxDigits, {this.allowPlus = false});

  final int maxDigits;
  final bool allowPlus;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var digits = 0;
    var wrotePlus = false;
    for (final rune in newValue.text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ') {
        buffer.write(ch);
        continue;
      }
      if (allowPlus && ch == '+' && !wrotePlus && buffer.isEmpty) {
        buffer.write(ch);
        wrotePlus = true;
        continue;
      }
      final code = ch.codeUnitAt(0);
      if (code >= 48 && code <= 57) {
        if (digits >= maxDigits) continue;
        buffer.write(ch);
        digits++;
      }
    }
    final text = buffer.toString();
    if (text == newValue.text) return newValue;
    final offset = newValue.selection.baseOffset.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
