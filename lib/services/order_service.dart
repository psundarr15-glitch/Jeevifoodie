import '../config/api_config.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  static Future<List<OrderSummary>> myOrders() async {
    final res = await ApiClient.get(ApiConfig.myOrders);
    return (res['orders'] as List? ?? [])
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<OrderTrackingInfo> track(String orderCode) async {
    final res = await ApiClient.get(ApiConfig.trackOrder(orderCode));
    return OrderTrackingInfo.fromJson(res);
  }

  /// Only allowed by the backend while the order is still 'placed' or
  /// 'confirmed' (see Api\OrderApiController::cancel) - the caller should
  /// hide/disable the cancel action once it moves past that.
  static Future<void> cancel({required int orderId, String? reason}) async {
    await ApiClient.post(ApiConfig.cancelOrder(orderId), {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }
}
