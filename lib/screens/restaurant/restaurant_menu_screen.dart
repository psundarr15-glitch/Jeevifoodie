import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/customer_service.dart';
import '../../services/cart_service.dart';
import '../../models/menu_item.dart';
import '../../models/cart_item.dart';
import '../../models/restaurant.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../cart/cart_screen.dart';
import '../food/food_detail_screen.dart';
import '../../widgets/quantity_stepper.dart';
import '../../l10n/app_localizations.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final int restaurantId;
  const RestaurantMenuScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  late Future<RestaurantMenuData> _future;
  Map<int, CartItem> _cartByMenuItem = {}; // menuItemId -> CartItem
  int _cartCount = 0;
  double _cartSubtotal = 0;
  final Set<int> _busy = {};
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _future = CustomerService.restaurantMenu(widget.restaurantId).then((data) {
      _selectedCategory = data.menu.keys.isNotEmpty ? data.menu.keys.first : null;
      return data;
    });
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cart = await CartService.view();
      if (!mounted) return;
      setState(() {
        _cartByMenuItem = {for (final it in cart.items) it.menuItemId: it};
        _cartCount = cart.count;
        _cartSubtotal = cart.subtotal;
      });
    } catch (_) {
      // not logged in / no cart yet - fine, treat as empty
    }
  }

  Future<void> _addItem(MenuItem item) async {
    setState(() => _busy.add(item.id));
    try {
      await CartService.add(menuItemId: item.id);
      await _loadCart();
      if (!mounted) return;
      context.read<AppState>().refreshCartCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotAddItem(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _changeQty(MenuItem item, int delta) async {
    final existing = _cartByMenuItem[item.id];
    if (existing == null) return;
    setState(() => _busy.add(item.id));
    try {
      await CartService.updateQuantity(cartItemId: existing.id, quantity: existing.quantity + delta);
      await _loadCart();
      if (!mounted) return;
      context.read<AppState>().refreshCartCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorLabel(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _openDetail(MenuItem item, bool restaurantOpen) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(
          item: item,
          restaurantOpen: restaurantOpen,
          initialQuantity: _cartByMenuItem[item.id]?.quantity ?? 0,
        ),
      ),
    );
    if (changed == true) {
      await _loadCart();
      if (mounted) context.read<AppState>().refreshCartCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<RestaurantMenuData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorLabel(snap.error.toString())));
          }
          final data = snap.data!;
          final restaurant = data.restaurant;
          final categories = data.menu.keys.toList();
          final selected = _selectedCategory ?? (categories.isNotEmpty ? categories.first : null);
          final items = selected != null ? (data.menu[selected] ?? []) : <MenuItem>[];

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 170,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(restaurant.name),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          restaurant.image != null
                              ? Image.network(restaurant.image!, fit: BoxFit.cover)
                              : Container(color: AppTheme.primary.withOpacity(0.15)),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black45],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 50,
                            child: _StatusPill(isOpen: restaurant.isOpen),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(AppLocalizations.of(context)!.ratingsCountLabel(restaurant.ratingCount.toString()), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.of(context)!.prepTimeRange(restaurant.prepTimeMin.toString(), restaurant.prepTimeMax.toString()), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(restaurant.cuisine ?? '', style: TextStyle(color: Colors.grey.shade600)),
                            if ((restaurant.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(restaurant.description!),
                            ],
                            const SizedBox(height: 10),
                            _LikeShareRow(restaurant: restaurant),
                          ],
                        ),
                      ),
                      if (!restaurant.isOpen)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_filled, color: Colors.red.shade400, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.restaurantClosedNotice,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (categories.length > 1)
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final cat = categories[i];
                              final isSelected = cat == selected;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      for (final item in items)
                        _MenuItemTile(
                          item: item,
                          restaurantOpen: restaurant.isOpen,
                          quantity: _cartByMenuItem[item.id]?.quantity ?? 0,
                          busy: _busy.contains(item.id),
                          onTap: () => _openDetail(item, restaurant.isOpen),
                          onAdd: () => _addItem(item),
                          onIncrease: () => _changeQty(item, 1),
                          onDecrease: () => _changeQty(item, -1),
                        ),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ],
              ),
              if (_cartCount > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primary,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())).then((_) => _loadCart()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.itemCountLabel(_cartCount.toString()), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                Text(AppLocalizations.of(context)!.totalAmountLabel(_cartSubtotal.toStringAsFixed(2)), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                Text(AppLocalizations.of(context)!.viewCart, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isOpen;
  const _StatusPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade600 : Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isOpen ? AppLocalizations.of(context)!.openNow : AppLocalizations.of(context)!.closedLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _LikeShareRow extends StatefulWidget {
  final Restaurant restaurant;
  const _LikeShareRow({required this.restaurant});

  @override
  State<_LikeShareRow> createState() => _LikeShareRowState();
}

class _LikeShareRowState extends State<_LikeShareRow> {
  late bool _liked = widget.restaurant.likedByMe;
  late int _count = widget.restaurant.likeCount;
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      final (liked, count) = await CustomerService.toggleLike(widget.restaurant.id);
      setState(() {
        _liked = liked;
        _count = count;
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _toggle,
          icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 18, color: _liked ? Colors.red : null),
          label: Text(AppLocalizations.of(context)!.likeCountLabel(_count.toString(), _count == 1 ? '' : 's')),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
        ),
      ],
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final bool restaurantOpen;
  final int quantity;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _MenuItemTile({
    required this.item,
    required this.restaurantOpen,
    required this.quantity,
    required this.busy,
    required this.onTap,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&h=200&fit=crop';
    final canOrder = restaurantOpen && item.isAvailable;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: item.isVeg ? Colors.green : Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (item.ratingCount > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 13, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text('${item.rating.toStringAsFixed(1)} (${item.ratingCount}+)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ],
                    ),
                    if (!item.isAvailable) ...[
                      const SizedBox(height: 4),
                      Text(AppLocalizations.of(context)!.currentlyUnavailable, style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.image?.isNotEmpty == true ? item.image! : fallbackImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(fallbackImage, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 96,
                    child: !canOrder
                        ? OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                            child: Text(restaurantOpen ? AppLocalizations.of(context)!.notAvailableShort : AppLocalizations.of(context)!.closedLabel, style: const TextStyle(fontSize: 12)),
                          )
                        : busy
                            ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                            : quantity == 0
                                ? OutlinedButton(
                                    onPressed: onAdd,
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                                    child: Text(AppLocalizations.of(context)!.addPlus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                : Center(
                                    child: QuantityStepper(
                                      quantity: quantity,
                                      onIncrease: onIncrease,
                                      onDecrease: onDecrease,
                                      compact: true,
                                    ),
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
