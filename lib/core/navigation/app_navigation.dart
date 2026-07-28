import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../router/app_router.dart';
import '../../data/static_data.dart';

/// Clears the session and navigates to the account suspended screen.
Future<void> logoutToSuspendedScreen(BuildContext context) async {
  try {
    context.read<WalletProvider>().clear();
  } catch (_) {}
  try {
    await context.read<AuthProvider>().logout();
  } catch (_) {
    // Still navigate even if logout fails.
  }
  appRouter.go('/account-suspended');
}

/// Clears the session and navigates to the login screen.
Future<void> logoutToLoginScreen(BuildContext context) async {
  try {
    context.read<WalletProvider>().clear();
  } catch (_) {}
  try {
    await context.read<AuthProvider>().logout();
  } catch (_) {
    // Still navigate even if logout fails.
  }
  if (context.mounted) {
    context.go('/login');
  } else {
    appRouter.go('/login');
  }
}

/// Pushes onto the root router so full-screen routes open above shell tabs.
void appNavigatePush(String location, {Object? extra}) {
  if (extra != null) {
    appRouter.push(location, extra: extra);
  } else {
    appRouter.push(location);
  }
}

/// Replaces the current route on the root router.
void appNavigatePushReplacement(String location, {Object? extra}) {
  if (extra != null) {
    appRouter.pushReplacement(location, extra: extra);
  } else {
    appRouter.pushReplacement(location);
  }
}

/// Pops when possible; otherwise navigates to [fallback] if provided.
void appNavigateBack(BuildContext context, {String? fallback}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  if (fallback != null && fallback.isNotEmpty) {
    router.go(fallback);
  }
}

String disputeFormRoute(String shipmentId, {bool travelerView = false, String? role}) {
  if (travelerView) return '/dispute-form/$shipmentId?traveler=true';
  if (role == 'receiver') return '/dispute-form/$shipmentId?role=receiver';
  return '/dispute-form/$shipmentId';
}

String disputeRoute(String shipmentId, {bool travelerView = false, String? role}) {
  if (travelerView) return '/dispute/$shipmentId?traveler=true';
  if (role == 'receiver') return '/dispute/$shipmentId?role=receiver';
  return '/dispute/$shipmentId';
}

String disputeOriginFallback(
  String shipmentId, {
  bool travelerView = false,
  String? role,
}) {
  if (travelerView) return '/shipment/$shipmentId?traveler=true';
  if (role == 'receiver') return '/receiver-tracking';
  return '/shipment/$shipmentId';
}

String disputeListFallback({bool travelerView = false, String? role}) {
  if (travelerView) return '/traveler-deliveries';
  if (role == 'receiver') return '/receiver-tracking';
  return '/track';
}

({bool travelerView, String? role}) disputeContextFromUri(Uri uri) {
  final role = uri.queryParameters['role'];
  return (
    travelerView: uri.queryParameters['traveler'] == 'true',
    role: role == 'receiver' ? role : null,
  );
}

/// Resolves a safe fallback route when the navigator stack cannot pop.
String? backFallbackFor(String path) {
  if (path.startsWith('/bid-requests/')) return '/home';
  if (path.startsWith('/dispute-form/')) {
    final id = path.substring('/dispute-form/'.length).split('?').first;
    if (id.isNotEmpty) return '/shipment/$id';
  }
  if (path.startsWith('/dispute/')) return '/track';
  if (path.startsWith('/shipment/')) return '/track';
  if (path.startsWith('/request/')) {
    final id = path.substring('/request/'.length);
    final matching = StaticData.matchingRequestById(id);
    if (matching != null) {
      return '/matching-requests/${matching.tripId}';
    }
    return '/matching-requests';
  }
  if (path.startsWith('/matching-requests/')) return '/matching-requests';
  if (path.startsWith('/traveler-bid-detail')) return '/traveler-bids';
  if (path.startsWith('/edit-posted-delivery/')) return '/my-posted-parcels';
  if (path.startsWith('/edit-trip/')) return '/traveler-trips';
  if (path.startsWith('/cancel-trip/')) return '/traveler-trips';

  return _routeFallbacks[path];
}

String? backFallbackForContext(BuildContext context) {
  final state = GoRouterState.of(context);
  final role = state.uri.queryParameters['role'];
  if (state.uri.path.startsWith('/dispute-form/')) {
    final id = state.pathParameters['id'];
    if (id != null && id.isNotEmpty) {
      return disputeOriginFallback(
        id,
        travelerView: state.uri.queryParameters['traveler'] == 'true',
        role: role,
      );
    }
  }
  if (state.uri.path.startsWith('/dispute/')) {
    return disputeListFallback(
      travelerView: state.uri.queryParameters['traveler'] == 'true',
      role: role,
    );
  }
  if (state.uri.path == '/bid-submitted') {
    final tripId = state.uri.queryParameters['tripId'];
    if (tripId != null && tripId.isNotEmpty) {
      return '/matching-requests/$tripId';
    }
  }
  if (state.uri.path == '/settings') {
    return switch (role) {
      'receiver' => '/receiver-profile',
      'traveler' => '/traveler-profile',
      _ => '/profile',
    };
  }
  if (state.uri.path == '/wallet' ||
      state.uri.path == '/wallet/top-up' ||
      state.uri.path == '/wallet/top-up/success' ||
      state.uri.path == '/change-password' ||
      state.uri.path == '/change-password/success' ||
      state.uri.path == '/kyc-status') {
    return switch (role) {
      'receiver' => '/settings?role=receiver',
      'traveler' => '/settings?role=traveler',
      _ => '/settings?role=sender',
    };
  }
  return backFallbackFor(state.uri.path);
}

void appNavigateBackFromContext(BuildContext context, {String? fallback}) {
  appNavigateBack(
    context,
    fallback: fallback ?? backFallbackForContext(context),
  );
}

const _routeFallbacks = <String, String>{
  '/settings': '/profile',
  '/wallet': '/profile',
  '/shipment-history': '/profile',
  '/transaction-history': '/profile',
  '/edit-profile': '/settings',
  '/edit-profile/success': '/settings',
  '/change-password': '/settings',
  '/change-password/success': '/settings',
  '/kyc-status': '/settings',
  '/security-logs': '/settings',
  '/legal/terms': '/register',
  '/delivery-type': '/home',
  '/parcel/create': '/discover-travelers',
  '/discover-trips': '/discover-travelers',
  '/add-meetup-locations': '/post-delivery',
  '/post-delivery': '/delivery-type',
  '/post-delivery/country-to-country': '/delivery-type',
  '/post-delivery/success': '/home',
  '/bids': '/home',
  '/bid-requests': '/home',
  '/my-posted-parcels': '/home',
  '/edit-posted-delivery': '/my-posted-parcels',
  '/sender-notifications': '/home',
  '/traveler-notifications': '/traveler-home',
  '/bid-accepted': '/bid-requests',
  '/bid-acceptance-payment': '/bid-requests',
  '/bid-payment-success': '/bid-acceptance-payment',
  '/sender-chat': '/sender-chats',
  '/sender-chats': '/home',
  '/payment': '/bids',
  '/payment-confirmed': '/track',
  '/trip-type': '/traveler-home',
  '/post-trip': '/trip-type',
  '/post-trip/country-to-country': '/trip-type',
  '/post-trip/success': '/traveler-home',
  '/edit-trip': '/traveler-trips',
  '/cancel-trip': '/traveler-trips',
  '/browse-requests': '/home',
  '/matching-requests': '/traveler-home',
  '/traveler-deliveries': '/traveler-home',
  '/traveler-bids': '/traveler-home',
  '/traveler-bid-detail': '/traveler-bids',
  '/traveler-chat': '/traveler-chats',
  '/traveler-chats': '/traveler-home',
  '/traveler-trips': '/traveler-home',
  '/traveler-profile': '/traveler-home',
  '/bid-submitted': '/traveler-deliveries',
  '/contact-support': '/track',
  '/contact-support/success': '/track',
  '/chat': '/sender-chats',
  '/receiver-chat': '/receiver-chats',
  '/receiver-chats': '/receiver-home',
  '/receiver-tracking': '/receiver-home',
  '/receiver-nfc-success': '/receiver-tracking',
  '/receiver-payment-approval': '/receiver-home',
  '/receiver-home/payment-approval': '/receiver-home',
  '/receiver-payment-confirmed': '/receiver-home',
  '/traveler-nfc-success': '/traveler-deliveries',
  '/nfc-confirm': '/track',
  '/nfc-confirm/success': '/track',
  '/delivery-review': '/track',
  '/delivery-review/success': '/home',
  '/wallet/top-up': '/wallet',
  '/wallet/top-up/success': '/wallet',
  '/wallet/withdrawal-success': '/wallet',
  '/register': '/welcome',
  '/login': '/welcome',
  '/login/verify-otp': '/login',
  '/login/otp-contact': '/login',
  '/login/otp': '/login/otp-contact',
  '/verify-account': '/role-selection',
  '/verify-account/otp': '/verify-account',
  '/forgot-password': '/login',
  '/forgot-password/otp': '/forgot-password',
  '/forgot-password/reset': '/forgot-password/otp',
  '/forgot-password/success': '/login',
  '/biometric/setup': '/login',
  '/biometric/login': '/login',
  '/biometric/success': '/home',
  '/biometric/unavailable': '/login',
  '/kyc': '/login',
  '/kyc/id-document': '/kyc',
  '/kyc/id-capture': '/kyc/id-document',
  '/kyc/id-preview': '/kyc/id-capture',
  '/kyc/id-complete': '/kyc',
  '/kyc/selfie': '/kyc',
  '/kyc/selfie/liveness': '/kyc/selfie',
  '/kyc/selfie/capture': '/kyc/selfie/liveness',
  '/kyc/selfie/preview': '/kyc/selfie/capture',
  '/kyc/selfie/processing': '/kyc/selfie',
  '/kyc/selfie/complete': '/kyc',
  '/kyc-approved': '/home',
  '/kyc-pending-review': '/kyc',
  '/kyc-rejected': '/kyc',
  '/account-suspended': '/welcome',
  '/welcome': '/',
};
