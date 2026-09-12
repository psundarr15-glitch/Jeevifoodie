import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../theme.dart';

/// Adds an item while enforcing the single-restaurant cart rule.
/// Returns true when the item was added successfully.
class CartRestaurantGuard {
  static Future<bool> add(BuildContext context, {required int menuItemId, required int restaurantId, int quantity = 1}) async {
    try {
      final cart = await CartService.view();
      final hasOtherRestaurant = cart.items.isNotEmpty &&
          cart.restaurantId != null &&
          cart.restaurantId != restaurantId;

      if (hasOtherRestaurant) {
        if (!context.mounted) return false;
        final confirmed = await _confirmReset(context);
        if (confirmed != true) return false;
        await _clearCart(cart.items);
      }

      await CartService.add(menuItemId: menuItemId, quantity: quantity);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add item: $e')),
        );
      }
      return false;
    }
  }

  static Future<void> _clearCart(List<CartItem> items) async {
    for (final item in items) {
      await CartService.updateQuantity(cartItemId: item.id, quantity: 0);
    }
    final refreshed = await CartService.view();
    if (refreshed.items.isNotEmpty) {
      throw Exception('Could not reset cart. Please try again.');
    }
  }

  static Future<bool?> _confirmReset(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('!', style: TextStyle(color: AppTheme.primary, fontSize: 30, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Are you sure you want to reset?', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                'You have items from another restaurant in your cart. If you continue, all previous items will be removed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary(context), height: 1.45, fontSize: 13.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                      child: const Text('No', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                      child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
