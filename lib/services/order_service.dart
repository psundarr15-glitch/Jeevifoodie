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
}
