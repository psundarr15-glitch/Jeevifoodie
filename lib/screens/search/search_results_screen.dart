import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../services/search_service.dart';
import '../../services/cart_service.dart';
import '../../state/app_state.dart';

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

class _ItemsTab extends StatelessWidget {
  final List<MenuItem> items;
  const _ItemsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Center(child: Text(t.noResultsFound, style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _ItemCard(item: items[i]),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final MenuItem item;
  const _ItemCard({required this.item});
  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late bool _liked = widget.item.likedByMe;
  bool _toggling = false;
  bool _addedToCart = false;
  bool _addingToCart = false;
  int _cartQty = 1;

  Future<void> _addOneToCart() async {
    if (_addingToCart || !widget.item.isAvailable) return;
    setState(() => _addingToCart = true);
    try {
      await CartService.add(menuItemId: widget.item.id, quantity: 1);
      if (!mounted) return;
      await context.read<AppState>().refreshCartCount();
      setState(() {
        _addedToCart = true;
        _cartQty = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotAddItem(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Future<void> _changeCartQty(int delta) async {
    if (_addingToCart) return;
    final next = _cartQty + delta;
    if (next < 1) return;
    setState(() => _addingToCart = true);
    try {
      await CartService.add(menuItemId: widget.item.id, quantity: delta);
      if (!mounted) return;
      await context.read<AppState>().refreshCartCount();
      setState(() => _cartQty = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotAddItem(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

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

    Future<void> openItem() async {
      final added = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => ItemDetailSheet(item: item),
      );
      if (mounted && added == true) {
        setState(() {
          _addedToCart = true;
          _cartQty = 1;
        });
      }
    }

    return GestureDetector(
      onTap: openItem,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        padding: const EdgeInsets.all(12),
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
                if (!item.isAvailable)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        t.notAvailableNow,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5))),
                      const SizedBox(width: 6),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700, width: 1.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.restaurantName != null) ...[
                    const SizedBox(height: 3),
                    Text(item.restaurantName!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                  if (item.ratingCount > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppTheme.gold),
                        const SizedBox(width: 3),
                        Text('${item.rating.toStringAsFixed(1)} (${item.ratingCount})', style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      if (!_addedToCart)
                        Material(
                          color: item.isAvailable ? AppTheme.primary : Colors.grey.shade300,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: item.isAvailable && !_addingToCart ? _addOneToCart : null,
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: Center(
                                child: _addingToCart
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.add, color: Colors.white, size: 21),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _InlineQtyButton(
                                icon: Icons.remove,
                                onTap: _cartQty > 1 ? () => _changeCartQty(-1) : null,
                                busy: _addingToCart,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('$_cartQty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                              ),
                              _InlineQtyButton(
                                icon: Icons.add,
                                onTap: () => _changeCartQty(1),
                                busy: _addingToCart,
                              ),
                            ],
                          ),
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


class _InlineQtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool busy;

  const _InlineQtyButton({required this.icon, required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 34,
        height: 36,
        child: Center(
          child: Icon(icon, size: 18, color: onTap == null ? Colors.white54 : Colors.white),
        ),
      ),
    );
  }
}
