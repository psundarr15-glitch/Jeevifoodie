import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../services/cart_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class FoodDetailScreen extends StatefulWidget {
  final MenuItem item;
  final bool restaurantOpen;
  final int initialQuantity;

  const FoodDetailScreen({
    super.key,
    required this.item,
    required this.restaurantOpen,
    this.initialQuantity = 0,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late int _qty = widget.initialQuantity > 0 ? widget.initialQuantity : 1;
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await CartService.add(menuItemId: widget.item.id, quantity: _qty);
      if (!mounted) return;
      await context.read<AppState>().refreshCartCount();
      Navigator.of(context).pop(true); // tell caller to refresh
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotAddItem(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=600&fit=crop';
    final item = widget.item;
    final canOrder = widget.restaurantOpen && item.isAvailable;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                item.image?.isNotEmpty == true ? item.image! : fallbackImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(fallbackImage, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: item.isVeg ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (item.ratingCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(AppLocalizations.of(context)!.ratingCountParen(item.ratingCount.toString()), style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(item.description!, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                    ],
                    if (!item.isAvailable) ...[
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.currentlyUnavailable, style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                    ] else if (!widget.restaurantOpen) ...[
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.restaurantClosedRightNow, style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                    ] else ...[
                      const SizedBox(height: 24),
                      Text(AppLocalizations.of(context)!.quantityLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _QtyButton(icon: Icons.remove, onTap: _qty > 1 ? () => setState(() => _qty--) : null),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          _QtyButton(icon: Icons.add, onTap: () => setState(() => _qty++)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: canOrder
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _adding ? null : _addToCart,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.primaryDark),
                  child: _adding
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.addToCartAmount((item.price * _qty).toStringAsFixed(2)), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.shopping_cart, size: 18),
                          ],
                        ),
                ),
              ),
            )
          : null,
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: onTap == null ? Colors.grey.shade300 : AppTheme.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey.shade400 : AppTheme.primary),
      ),
    );
  }
}
