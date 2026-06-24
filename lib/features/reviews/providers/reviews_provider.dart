import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/review_model.dart';

class ReviewsProvider extends ChangeNotifier {
  List<ReviewModel> _walkerReviews = [];
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> get walkerReviews => List.unmodifiable(_walkerReviews);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get averageRating {
    if (_walkerReviews.isEmpty) return 0;
    final sum = _walkerReviews.fold<int>(0, (p, r) => p + r.rating);
    return sum / _walkerReviews.length;
  }

  Future<void> loadWalkerReviews(String walkerId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('walker_id', walkerId)
          .order('created_at', ascending: false);
      _walkerReviews =
          (data as List).map((e) => ReviewModel.fromMap(e)).toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar calificaciones.';
      debugPrint('[ReviewsProvider] loadWalkerReviews: $e');
    }
    _setLoading(false);
  }

  Future<Map<String, dynamic>> getWalkerRatingSummary(String walkerId) async {
    try {
      final data = await SupabaseService.client
          .from('reviews')
          .select('rating')
          .eq('walker_id', walkerId);
      final list = data as List;
      if (list.isEmpty) return {'average': 0.0, 'count': 0};
      final sum = list.fold<int>(0, (p, r) => p + (r['rating'] as int));
      return {
        'average': sum / list.length,
        'count': list.length,
      };
    } catch (e) {
      debugPrint('[ReviewsProvider] getWalkerRatingSummary: $e');
      return {'average': 0.0, 'count': 0};
    }
  }

  Future<bool> hasReviewed(String bookingId) async {
    try {
      final data = await SupabaseService.client
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      debugPrint('[ReviewsProvider] hasReviewed: $e');
      return false;
    }
  }

  Future<bool> createReview({
    required String walkerId,
    required String ownerId,
    required String bookingId,
    required int rating,
    String? comment,
    String? ownerName,
  }) async {
    try {
      await SupabaseService.client.from('reviews').insert({
        'walker_id': walkerId,
        'owner_id': ownerId,
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
        'owner_name': ownerName,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[ReviewsProvider] createReview: $e');
      return false;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
