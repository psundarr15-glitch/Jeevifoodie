class OrderSummary {
  final int id;
  final String orderCode;
  final String status;
  final double total;
  final String? placedAt;
  final String paymentMethod;
  final String? imageUrl;

  OrderSummary({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.total,
    this.placedAt,
    this.paymentMethod = 'cod',
    this.imageUrl,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        id: int.parse(j['id'].toString()),
        orderCode: j['order_code']?.toString() ?? '',
        status: j['order_status']?.toString() ?? 'placed',
        total: double.tryParse(j['total']?.toString() ?? '') ?? 0,
        placedAt: j['placed_at']?.toString(),
        paymentMethod: j['payment_method']?.toString() ?? 'cod',
        imageUrl: (j['image_url']?.toString().trim().isEmpty ?? true) ? null : j['image_url'].toString(),
      );
}

class OrderTrackingInfo {
  final int orderId;
  final String orderStatus;
  final int? etaMin;
  final int? deliveryPartnerId;
  final String? partnerName;
  final String? partnerPhone;
  final double? lat;
  final double? lng;
  final double? restaurantLat;
  final double? restaurantLng;
  final int? restaurantId;
  final String? restaurantName;
  final bool reviewed;
  final String? deliveryOtp;
  final bool deliveryOtpRequired;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> history;

  OrderTrackingInfo({
    required this.orderId,
    required this.orderStatus,
    this.etaMin,
    this.deliveryPartnerId,
    this.partnerName,
    this.partnerPhone,
    this.lat,
    this.lng,
    this.restaurantLat,
    this.restaurantLng,
    this.restaurantId,
    this.restaurantName,
    this.reviewed = false,
    this.deliveryOtp,
    this.deliveryOtpRequired = false,
    this.items = const [],
    this.history = const [],
  });

  factory OrderTrackingInfo.fromJson(Map<String, dynamic> j) => OrderTrackingInfo(
        orderId: int.tryParse((j['order'] as Map<String, dynamic>?)?['id']?.toString() ?? '') ?? 0,
        orderStatus: j['order_status']?.toString() ?? 'placed',
        etaMin: j['eta_min'] != null ? int.tryParse(j['eta_min'].toString()) : null,
        deliveryPartnerId: j['delivery_partner_id'] != null ? int.tryParse(j['delivery_partner_id'].toString()) : null,
        partnerName: j['partner_name']?.toString(),
        partnerPhone: j['partner_phone']?.toString(),
        lat: j['lat'] != null ? double.tryParse(j['lat'].toString()) : null,
        lng: j['lng'] != null ? double.tryParse(j['lng'].toString()) : null,
        restaurantLat: j['restaurant_lat'] != null ? double.tryParse(j['restaurant_lat'].toString()) : null,
        restaurantLng: j['restaurant_lng'] != null ? double.tryParse(j['restaurant_lng'].toString()) : null,
        restaurantId: j['restaurant_id'] != null ? int.tryParse(j['restaurant_id'].toString()) : null,
        restaurantName: j['restaurant_name']?.toString(),
        reviewed: j['reviewed'] == true,
        deliveryOtp: j['delivery_otp']?.toString(),
        deliveryOtpRequired: j['delivery_otp_required'] == true ||
            j['delivery_otp_required']?.toString().toLowerCase() == 'true' ||
            j['delivery_otp_required']?.toString() == '1' ||
            (j['delivery_otp']?.toString().trim().isNotEmpty ?? false),
        items: (j['items'] as List? ?? []).cast<Map<String, dynamic>>(),
        history: (j['history'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
}
