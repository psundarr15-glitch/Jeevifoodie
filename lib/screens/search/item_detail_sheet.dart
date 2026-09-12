import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../services/search_service.dart';
import '../../services/cart_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import '../restaurant/restaurant_menu_screen.dart';

class ItemDetailSheet extends StatefulWidget {
  final MenuItem item;
  const ItemDetailSheet({super.key, required this.item});

  @override
  State<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<ItemDetailSheet> {
  late bool _liked = widget.item.likedByMe;
  late int _likeCount = widget.item.likeCount;
  bool _toggling = false;
  int _qty = 1;
  bool _adding = false;

  Future<void> _addToCart() async {
    if (_adding || !widget.item.isAvailable || !widget.item.isOpen) return;
    setState(() => _adding = true);
    try {
      await CartService.add(menuItemId: widget.item.id, quantity: _qty);
      if (!mounted) return;
      await context.read<AppState>().refreshCartCount();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotAddItem(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_toggling) return;
    setState(() {
      _toggling = true;
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    try {
      final (liked, count) = await SearchService.toggleItemLike(widget.item.id);
      if (mounted) setState(() { _liked = liked; _likeCount = count; });
    } catch (_) {
      if (mounted) setState(() { _liked = !_liked; _likeCount += _liked ? 1 : -1; });
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final item = widget.item;
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&h=400&fit=crop';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      item.image?.isNotEmpty == true ? item.image! : fallbackImage,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(fallbackImage, width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (item.restaurantName != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurantId: item.restaurantId)));
                            },
                            child: Text(item.restaurantName!, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                                  i < item.rating.round() ? Icons.star : Icons.star_border,
                                  color: AppTheme.gold,
                                  size: 16,
                                )),
                            const SizedBox(width: 6),
                            Text('(${item.ratingCount})', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked ? Colors.green.shade600 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.descriptionLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700, width: 1.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(item.isVeg ? t.vegLabel : t.nonVegLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (item.description?.isNotEmpty ?? false) ? item.description! : item.name,
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              if (!item.isOpen) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(t.storeCurrentlyClosed, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ] else if (!item.isAvailable) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(t.notAvailableNow, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                ),
              ] else ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.quantityLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyButton(icon: Icons.remove, onTap: _qty > 1 ? () => setState(() => _qty--) : null),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Text('$_qty', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                          _QtyButton(icon: Icons.add, onTap: _qty < 99 ? () => setState(() => _qty++) : null),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _adding ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.primaryDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _adding
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(t.addToCartAmount((item.price * _qty).toStringAsFixed(2)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                            const SizedBox(width: 8),
                            const Icon(Icons.shopping_cart_rounded, size: 19),
                          ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
