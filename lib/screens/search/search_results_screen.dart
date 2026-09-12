import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../services/search_service.dart';
import '../../services/cart_service.dart';
import '../../models/cart_item.dart';
import '../../state/app_state.dart';
import '../../widgets/quantity_stepper.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/restaurant_list_tile.dart';
import '../restaurant/restaurant_menu_screen.dart';
import 'item_detail_sheet.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  late final TextEditingController _searchController = TextEditingController(text: widget.initialQuery);
  late Future<SearchResults> _future = SearchService.search(widget.initialQuery);

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    SearchService.addRecentSearch(trimmed);
    setState(() => _future = SearchService.search(trimmed));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _runSearch,
                      decoration: InputDecoration(
                        hintText: t.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            Navigator.of(context).pop();
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<SearchResults>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('${snap.error}'));
                  }
                  final results = snap.data!;
                  final total = results.items.length + results.restaurants.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(text: '$total ', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                              TextSpan(text: t.resultsFound, style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primary,
                        indicatorColor: AppTheme.primary,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: '${t.itemLabel} (${results.items.length})'),
                          Tab(text: '${t.restaurantsLabel} (${results.restaurants.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _ItemsTab(items: results.items),
                            _RestaurantsTab(restaurants: results.restaurants),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsTab extends StatefulWidget {
  final List<MenuItem> items;
  const _ItemsTab({required this.items});

  @override
  State<_ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<_ItemsTab> {
  Map<int, CartItem> _cartByMenuItem = {};
  final Set<int> _busy = <int>{};

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cart = await CartService.view();
      if (!mounted) return;
      setState(() => _cartByMenuItem = {for (final item in cart.items) item.menuItemId: item});
    } catch (_) {
      // Guests/offline users can still browse search results.
    }
  }

  Future<void> _add(MenuItem item) async {
    if (_busy.contains(item.id) || !item.isAvailable || !item.isOpen) return;
    setState(() => _busy.add(item.id));
    try {
      await CartService.add(menuItemId: item.id);
      await _loadCart();
      if (!mounted) return;
      await context.read<AppState>().refreshCartCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} added to cart')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotAddItem(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _changeQty(MenuItem item, int delta) async {
    final existing = _cartByMenuItem[item.id];
    if (existing == null || _busy.contains(item.id)) return;
    final next = existing.quantity + delta;
    if (next < 1 || next > 99) return;
    setState(() => _busy.add(item.id));
    try {
      await CartService.updateQuantity(cartItemId: existing.id, quantity: next);
      await _loadCart();
      if (!mounted) return;
      await context.read<AppState>().refreshCartCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLabel(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _openDetail(MenuItem item) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ItemDetailSheet(item: item),
    );
    await _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (widget.items.isEmpty) {
      return Center(child: Text(t.noResultsFound, style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final item = widget.items[i];
        final cartItem = _cartByMenuItem[item.id];
        return _ItemCard(
          item: item,
          quantity: cartItem?.quantity ?? 0,
          busy: _busy.contains(item.id),
          onTap: () => _openDetail(item),
          onAdd: () => _add(item),
          onIncrease: () => _changeQty(item, 1),
          onDecrease: () => _changeQty(item, -1),
        );
      },
    );
  }
}

class _ItemCard extends StatefulWidget {
  final MenuItem item;
  final int quantity;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _ItemCard({
    required this.item,
    required this.quantity,
    required this.busy,
    required this.onTap,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late bool _liked = widget.item.likedByMe;
  bool _toggling = false;

  Future<void> _toggleLike() async {
    if (_toggling) return;
    setState(() { _toggling = true; _liked = !_liked; });
    try {
      final (liked, _) = await SearchService.toggleItemLike(widget.item.id);
      if (mounted) setState(() => _liked = liked);
    } catch (_) {
      if (mounted) setState(() => _liked = !_liked);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final t = AppLocalizations.of(context)!;
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&h=200&fit=crop';
    final canOrder = item.isAvailable && item.isOpen;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Opacity(
                    opacity: item.isAvailable ? 1 : 0.4,
                    child: Image.network(
                      item.image?.isNotEmpty == true ? item.image! : fallbackImage,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(fallbackImage, width: 84, height: 84, fit: BoxFit.cover),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: _toggleLike,
                    child: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: _liked ? Colors.green.shade600 : Colors.white,
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5))),
                      const SizedBox(width: 6),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700, width: 1.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700))),
                      ),
                    ],
                  ),
                  if (item.restaurantName != null) ...[
                    const SizedBox(height: 3),
                    Text(item.restaurantName!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (item.ratingCount > 0) ...[
                    const SizedBox(height: 3),
                    Row(children: [const Icon(Icons.star, size: 14, color: AppTheme.gold), const SizedBox(width: 3), Text('${item.rating.toStringAsFixed(1)} (${item.ratingCount})', style: const TextStyle(fontSize: 12.5))]),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      if (!canOrder)
                        Text(item.isOpen ? t.notAvailableShort : t.closedLabel, style: TextStyle(color: Colors.red.shade500, fontWeight: FontWeight.w700, fontSize: 11.5))
                      else if (widget.busy)
                        const SizedBox(width: 74, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                      else if (widget.quantity == 0)
                        SizedBox(
                          height: 34,
                          child: OutlinedButton(
                            onPressed: widget.onAdd,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(t.addPlus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                        )
                      else
                        QuantityStepper(
                          quantity: widget.quantity,
                          onIncrease: widget.onIncrease,
                          onDecrease: widget.onDecrease,
                          compact: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantsTab extends StatelessWidget {
  final List<Restaurant> restaurants;
  const _RestaurantsTab({required this.restaurants});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (restaurants.isEmpty) {
      return Center(child: Text(t.noResultsFound, style: TextStyle(color: Colors.grey.shade600)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: restaurants.length,
      itemBuilder: (context, i) {
        final r = restaurants[i];
        return RestaurantListTile(
          restaurant: r,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurantId: r.id))),
        );
      },
    );
  }
}
