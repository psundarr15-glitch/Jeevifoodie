import '../config/api_config.dart';
import 'api_client.dart';

class CouponResult {
  final double discount;
  final int couponId;
  CouponResult({required this.discount, required this.couponId});
}

class CheckoutService {
  static Future<CouponResult> applyCoupon({required String code, required double subtotal}) async {
    final res = await ApiClient.post(ApiConfig.applyCoupon, {
      'code': code,
      'subtotal': subtotal,
    });
    return CouponResult(
      discount: double.tryParse(res['discount']?.toString() ?? '') ?? 0,
      couponId: int.tryParse(res['coupon_id']?.toString() ?? '') ?? 0,
    );
  }

  static Future<Map<String, dynamic>> createCardPayment({required int addressId, int? couponId}) async {
    final res = await ApiClient.post(ApiConfig.createCardPayment, {
      'address_id': addressId,
      if (couponId != null) 'coupon_id': couponId,
    });
    return res;
  }

  static Future<Map<String, dynamic>> verifyCardPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await ApiClient.post(ApiConfig.verifyCardPayment, {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    });
    return res['order'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> placeOrder({
    required int addressId,
    required String paymentMethod,
    double discount = 0,
    int? couponId,
  }) async {
    final res = await ApiClient.post(ApiConfig.placeOrder, {
      'address_id': addressId,
      'payment_method': paymentMethod,
      'discount': discount,
      if (couponId != null) 'coupon_id': couponId,
    });
    return res['order'] as Map<String, dynamic>;
  }
}
