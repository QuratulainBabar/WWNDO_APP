import 'package:flutter/widgets.dart';

/// Dismisses the soft keyboard when the user taps outside a focused text field.
///
/// Prefer this as [EditableText.onTapOutside] instead of wrapping screens in a
/// [GestureDetector] that unfocuses on tap. That pattern races with focus on
/// MIUI / ColorOS and can reserve keyboard space without showing the IME
/// (flutter/flutter#185675).
void dismissKeyboardOnTapOutside(PointerDownEvent event) {
  FocusManager.instance.primaryFocus?.unfocus();
}
