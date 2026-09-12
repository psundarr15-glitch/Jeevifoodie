import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../services/cart_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/cart_restaurant_guard.dart';

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
      final added = await CartRestaurantGuard.add(context, menuItemId: widget.item.id, restaurantId: widget.item.restaurantId, quantity: _qty);
      if (!added || !mounted) return;
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
      backgroundColor: AppTheme.scaffoldBg(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: AppTheme.surface(context),
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.32),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.image?.isNotEmpty == true ? item.image! : fallbackImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(fallbackImage, fit: BoxFit.cover),
                  ),
                  // Bottom scrim so the rounded content sheet below reads as
                  // one continuous premium surface instead of a hard cut.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 90,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0), AppTheme.scaffoldBg(context)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
                ),
                transform: Matrix4.translationValues(0, -22, 0),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: item.isVeg ? const Color(0xFF12A968) : const Color(0xFFE5484D)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.name,
                              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context), letterSpacing: -0.4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 13, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        if (item.ratingCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.ratingCountParen(item.ratingCount.toString()),
                              style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13.5)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.4)),
                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(item.description!, style: TextStyle(color: AppTheme.textSecondary(context), height: 1.45, fontSize: 14.5)),
                    ],
                    if (!item.isAvailable) ...[
                      const SizedBox(height: 18),
                      _WarningBanner(text: AppLocalizations.of(context)!.currentlyUnavailable),
                    ] else if (!widget.restaurantOpen) ...[
                      const SizedBox(height: 18),
                      _WarningBanner(text: AppLocalizations.of(context)!.restaurantClosedRightNow),
                    ] else ...[
                      const SizedBox(height: 26),
                      Text(AppLocalizations.of(context)!.quantityLabel,
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyButton(icon: Icons.remove, onTap: _qty > 1 ? () => setState(() => _qty--) : null),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                              child: Text('$_qty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context))),
                            ),
                            _QtyButton(icon: Icons.add, onTap: () => setState(() => _qty++)),
                          ],
                        ),
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
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowColored(AppTheme.gold),
                  ),
                  child: ElevatedButton(
                    onPressed: _adding ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.primaryDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                    ),
                    child: _adding
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppLocalizations.of(context)!.addToCartAmount((item.price * _qty).toStringAsFixed(2)),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                              const SizedBox(width: 8),
                              const Icon(Icons.shopping_cart, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Soft rounded banner for "unavailable" / "closed" messaging — reads as
/// an intentional status card rather than plain red warning text.
class _WarningBanner extends StatelessWidget {
  final String text;
  const _WarningBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5484D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFE5484D)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFE5484D), fontWeight: FontWeight.w700))),
        ],
      ),
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
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: onTap == null ? null : AppTheme.primaryGradient,
          color: onTap == null ? AppTheme.borderColor(context).withOpacity(0.3) : null,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: onTap == null ? AppTheme.textSecondary(context) : Colors.white),
      ),
    );
  }
}
