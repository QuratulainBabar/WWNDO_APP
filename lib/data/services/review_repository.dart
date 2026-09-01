import '../../core/api/api_client.dart';
import '../../core/config/demo_mode.dart';
import '../models/review.dart';
import '../models/wallet_role.dart';
import '../static_data.dart';

/// Backend reviews API (profile "Recent reviews").
class ReviewRepository {
  ReviewRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// GET /api/v1/reviews?role=&limit=
  Future<List<Review>> listMyReviews(
    WalletRole role, {
    int limit = 20,
  }) async {
    if (_isDemoMode) {
      return List<Review>.from(StaticData.reviews);
    }

    final data = await _apiClient.get(
      '/reviews?role=${role.queryParam}&limit=$limit',
      authenticated: true,
    );
    final list = data['reviews'];
    if (list is! List) return const <Review>[];
    return list
        .whereType<Map>()
        .map((item) => Review.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// POST /api/v1/reviews
  Future<Review> createReview({
    required String revieweeId,
    required WalletRole revieweeRole,
    required int rating,
    required String text,
    String? shipmentId,
  }) async {
    if (_isDemoMode) {
      return Review(
        reviewerName: 'You',
        initial: 'Y',
        rating: rating.clamp(1, 5),
        text: text.trim(),
        date: 'Just now',
        shipmentId: shipmentId,
      );
    }

    final data = await _apiClient.post(
      '/reviews',
      body: {
        'revieweeId': revieweeId,
        'role': revieweeRole.queryParam,
        'rating': rating.clamp(1, 5),
        'text': text.trim(),
        if (shipmentId != null && shipmentId.trim().isNotEmpty)
          'shipmentId': shipmentId.trim(),
      },
      authenticated: true,
    );
    return Review.fromJson(data);
  }
}
