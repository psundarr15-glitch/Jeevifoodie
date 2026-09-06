import '../config/api_config.dart';
import 'api_client.dart';

class ReviewService {
  static Future<void> submit({
    required int orderId,
    required int rating,
    int? partnerRating,
    String? comment,
  }) async {
    await ApiClient.post(ApiConfig.reviewStore, {
      'order_id': orderId,
      'rating': rating,
      if (partnerRating != null) 'partner_rating': partnerRating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }
}
