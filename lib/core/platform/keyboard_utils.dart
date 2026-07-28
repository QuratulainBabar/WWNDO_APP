import 'package:flutter/services.dart';
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

/// Forces the soft keyboard to show.
///
/// On Xiaomi HyperOS / MIUI and ColorOS the field can stay focused while the
/// IME was dismissed; a second [FocusNode.requestFocus] is a no-op, so callers
/// must invoke [TextInput.show] explicitly (flutter/flutter#176688).
///
/// Set [retry] for `obscureText` fields — HyperOS secure keyboard often drops
/// the first show request (flutter/flutter#166311).
void ensureSoftKeyboardVisible({bool retry = false}) {
  SystemChannels.textInput.invokeMethod('TextInput.show');
  if (!retry) return;
  Future<void>.delayed(const Duration(milliseconds: 120), () {
    SystemChannels.textInput.invokeMethod('TextInput.show');
  });
}

/// Requests focus (if needed) and shows the soft keyboard.
///
/// Use after programmatic [FocusNode.requestFocus] on OEM-sensitive screens.
void requestSoftKeyboard(FocusNode node, {bool retry = false}) {
  if (!node.hasFocus) {
    node.requestFocus();
  }
  ensureSoftKeyboardVisible(retry: retry);
}
