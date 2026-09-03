/// Tracks an in-progress Stripe Connect onboarding session so the app can
/// open the in-app success screen when the user returns from the browser.
class StripeConnectReturn {
  StripeConnectReturn._();

  static bool awaiting = false;
  static String? role;
  static DateTime? openedAt;

  static void markOpened({String? role}) {
    awaiting = true;
    StripeConnectReturn.role = role;
    openedAt = DateTime.now();
  }

  static bool get isReturnDue {
    if (!awaiting) return false;
    final started = openedAt;
    if (started == null) return true;
    return DateTime.now().difference(started) >= const Duration(seconds: 8);
  }

  static bool consume() {
    if (!awaiting) return false;
    awaiting = false;
    openedAt = null;
    return true;
  }
}
