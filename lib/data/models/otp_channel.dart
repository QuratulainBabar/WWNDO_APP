enum OtpChannel {
  email,
  sms,
  whatsapp,
}

extension OtpChannelX on OtpChannel {
  String get label => switch (this) {
        OtpChannel.email => 'Email',
        OtpChannel.sms => 'SMS',
        OtpChannel.whatsapp => 'WhatsApp',
      };

  String get apiMethod => switch (this) {
        OtpChannel.email => 'email',
        OtpChannel.sms => 'phone',
        OtpChannel.whatsapp => 'whatsapp',
      };

  static OtpChannel fromApiMethod(String method) => switch (method) {
        'email' => OtpChannel.email,
        'whatsapp' => OtpChannel.whatsapp,
        _ => OtpChannel.sms,
      };
}

enum OtpPurpose {
  login,
  passwordReset,
  verifyEmail,
  verifyPhone,
}

/// Arguments for the cross-verification OTP screen (email / phone).
class CrossVerificationOtpFlow {
  const CrossVerificationOtpFlow({
    required this.channel,
    this.returnRoute = '/verify-account',
    this.continueToHomeOnSuccess = false,
  });

  final OtpChannel channel;
  final String returnRoute;

  /// After email OTP during onboarding, go straight to the role home.
  final bool continueToHomeOnSuccess;
}
