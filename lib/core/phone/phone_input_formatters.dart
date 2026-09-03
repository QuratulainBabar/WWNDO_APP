import 'package:flutter/services.dart';

import 'phone_countries.dart';

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

/// Formats the national number as the user types, inserting spaces to match
/// the selected country's example (e.g. FR `6 12 34 56 78`, US `202 555 0123`).
class PhoneNationalAsYouTypeFormatter extends TextInputFormatter {
  const PhoneNationalAsYouTypeFormatter(this.country);

  final PhoneCountry country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = PhoneCountries.formatNationalAsYouType(
      newValue.text,
      country,
    );

    // Map caret to the same digit index in the formatted string.
    final raw = newValue.text;
    final sel = newValue.selection.baseOffset;
    var digitIndex = 0;
    final end = sel.clamp(0, raw.length);
    for (var i = 0; i < end; i++) {
      final code = raw.codeUnitAt(i);
      if (code >= 48 && code <= 57) digitIndex++;
    }

    var offset = formatted.length;
    if (digitIndex == 0) {
      offset = 0;
    } else {
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        final code = formatted.codeUnitAt(i);
        if (code >= 48 && code <= 57) {
          seen++;
          if (seen == digitIndex) {
            offset = i + 1;
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset.clamp(0, formatted.length)),
    );
  }
}
