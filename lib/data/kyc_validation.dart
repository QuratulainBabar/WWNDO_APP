import '../data/models/auth_user.dart';

/// KYC gate using authenticated user record from the API.
abstract final class KycValidation {
  static String? validateApproved(AuthUser? user) {
    if (user == null) {
      return 'Please sign in to continue.';
    }
    final status = (user.kycStatus).trim().toLowerCase();
    if (status == 'approved') return null;
    if (status == 'pending' || status == 'submitted') {
      return 'Identity verification is still under review.';
    }
    if (status == 'rejected') {
      return 'Identity verification was rejected. Please resubmit your documents.';
    }
    return 'Complete identity verification before posting trips or deliveries.';
  }
}
