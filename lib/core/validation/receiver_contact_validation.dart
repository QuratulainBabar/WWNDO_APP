import '../../data/models/auth_user.dart';

/// Ensures parcel receiver contact details belong to a separate account
/// from the logged-in sender (sender / traveler / receiver use different Gmails).
class ReceiverContactValidation {
  ReceiverContactValidation._();

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static String? validateEmail(
    String receiverEmail, {
    String? senderEmail,
  }) {
    final email = receiverEmail.trim();
    if (email.isEmpty) return 'Enter the receiver\'s email.';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) return 'Enter a valid receiver email.';

    final sender = senderEmail?.trim().toLowerCase();
    if (sender != null && sender.isNotEmpty && email.toLowerCase() == sender) {
      return 'Receiver email must be different from your sender Gmail. '
          'The receiver should sign in with their own Gmail account.';
    }
    return null;
  }

  static String? validatePhone(
    String receiverPhone, {
    String? senderPhone,
  }) {
    if (receiverPhone.trim().isEmpty) {
      return 'Enter the receiver\'s phone number.';
    }
    final receiverDigits = _digitsOnly(receiverPhone);
    if (receiverDigits.length < 8) {
      return 'Enter a valid receiver phone number.';
    }

    final senderDigits = _digitsOnly(senderPhone ?? '');
    if (senderDigits.isNotEmpty && receiverDigits == senderDigits) {
      return 'Receiver phone must be different from your sender phone. '
          'Each role should use its own account.';
    }
    return null;
  }

  static String? validateEmailForUser(String receiverEmail, AuthUser? user) =>
      validateEmail(receiverEmail, senderEmail: user?.email);

  static String? validatePhoneForUser(String receiverPhone, AuthUser? user) =>
      validatePhone(receiverPhone, senderPhone: user?.phone);
}
