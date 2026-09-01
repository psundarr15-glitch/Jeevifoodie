class OrderSummary {
  final int id;
  final String orderCode;
  final String status;
  final double total;
  final String? placedAt;
  final String paymentMethod;

  OrderSummary({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.total,
    this.placedAt,
    this.paymentMethod = 'cod',
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        id: int.parse(j['id'].toString()),
        orderCode: j['order_code']?.toString() ?? '',
        status: j['order_status']?.toString() ?? 'placed',
        total: double.tryParse(j['total']?.toString() ?? '') ?? 0,
        placedAt: j['placed_at']?.toString(),
        paymentMethod: j['payment_method']?.toString() ?? 'cod',
      );
}

class OrderTrackingInfo {
  final String orderStatus;
  final int? etaMin;
  final String? partnerName;
  final String? partnerPhone;
  final double? lat;
  final double? lng;
  final double? restaurantLat;
  final double? restaurantLng;
  final int? restaurantId;
  final String? restaurantName;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> history;

  OrderTrackingInfo({
    required this.orderStatus,
    this.etaMin,
    this.partnerName,
    this.partnerPhone,
    this.lat,
    this.lng,
    this.restaurantLat,
    this.restaurantLng,
    this.restaurantId,
    this.restaurantName,
    this.items = const [],
    this.history = const [],
  });

  factory OrderTrackingInfo.fromJson(Map<String, dynamic> j) => OrderTrackingInfo(
        orderStatus: j['order_status']?.toString() ?? 'placed',
        etaMin: j['eta_min'] != null ? int.tryParse(j['eta_min'].toString()) : null,
        partnerName: j['partner_name']?.toString(),
        partnerPhone: j['partner_phone']?.toString(),
        lat: j['lat'] != null ? double.tryParse(j['lat'].toString()) : null,
        lng: j['lng'] != null ? double.tryParse(j['lng'].toString()) : null,
        restaurantLat: j['restaurant_lat'] != null ? double.tryParse(j['restaurant_lat'].toString()) : null,
        restaurantLng: j['restaurant_lng'] != null ? double.tryParse(j['restaurant_lng'].toString()) : null,
        restaurantId: j['restaurant_id'] != null ? int.tryParse(j['restaurant_id'].toString()) : null,
        restaurantName: j['restaurant_name']?.toString(),
        items: (j['items'] as List? ?? []).cast<Map<String, dynamic>>(),
        history: (j['history'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
}
