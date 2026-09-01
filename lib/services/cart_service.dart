import '../config/api_config.dart';
import '../models/cart_item.dart';
import 'api_client.dart';

class CartSnapshot {
  final List<CartItem> items;
  final int count;
  final double subtotal;
  CartSnapshot({required this.items, required this.count, required this.subtotal});

  factory CartSnapshot.fromJson(Map<String, dynamic> j) => CartSnapshot(
        items: (j['items'] as List? ?? []).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
        count: int.tryParse(j['cart_count']?.toString() ?? '') ?? 0,
        subtotal: double.tryParse(j['cart_subtotal']?.toString() ?? '') ?? 0,
      );
}

class CartService {
  static Future<CartSnapshot> view() async {
    final res = await ApiClient.get(ApiConfig.cartView);
    return CartSnapshot.fromJson(res);
  }

  static Future<CartSnapshot> add({required int menuItemId, int quantity = 1}) async {
    final res = await ApiClient.post(ApiConfig.cartAdd, {
      'menu_item_id': menuItemId,
      'quantity': quantity,
    });
    // add() doesn't return items list, so caller should refresh view() if it needs the list.
    return CartSnapshot(items: const [], count: int.tryParse(res['cart_count']?.toString() ?? '') ?? 0, subtotal: double.tryParse(res['cart_subtotal']?.toString() ?? '') ?? 0);
  }

  static Future<void> updateQuantity({required int cartItemId, required int quantity}) async {
    await ApiClient.post(ApiConfig.cartUpdate, {
      'cart_item_id': cartItemId,
      'quantity': quantity,
    });
  }
}
