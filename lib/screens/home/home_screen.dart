import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../models/menu_item.dart';
import '../../theme.dart';
import '../restaurant/restaurant_menu_screen.dart';
import '../restaurant/restaurant_list_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/notification_bell.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = CustomerService.home();
  }

  Future<void> _refresh() async {
    setState(() => _future = CustomerService.home());
    await _future;
  }

  void _browseAll() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantListScreen()));
  void _openSearch() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<HomeData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 80),
                Center(child: Text(AppLocalizations.of(context)!.couldNotLoadHome(snap.error.toString()))),
              ]);
            }
            final data = snap.data!;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _GreenHeader(onSearchTap: _openSearch),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.coupons.isNotEmpty) _BannerCarousel(coupons: data.coupons, onOrderNow: _browseAll),
                        if (data.coupons.isNotEmpty) const SizedBox(height: 24),
                        if (data.categories.isNotEmpty) _CategoryRow(categories: data.categories),
                        const SizedBox(height: 24),
                        if (data.nearbyStores.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(AppLocalizations.of(context)!.nearbyStores, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          Text(AppLocalizations.of(context)!.nearbyStoresSubtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _ViewAllPill(onTap: _browseAll),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                if (data.nearbyStores.isNotEmpty) ...[
                  SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: data.nearbyStores.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) {
                        final r = data.nearbyStores[i];
                        return _HomeRestaurantCard(
                          restaurant: r,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurantId: r.id)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.popularRestaurants, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _ViewAllPill(onTap: _browseAll),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.restaurants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) {
                      final r = data.restaurants[i];
                      return _HomeRestaurantCard(
                        restaurant: r,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurantId: r.id)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (data.popularItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(AppLocalizations.of(context)!.popularItems, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: data.popularItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) {
                        final item = data.popularItems[i];
                        return _PopularItemCard(
                          item: item,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurantId: item.restaurantId)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (data.coupons.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(AppLocalizations.of(context)!.bestDealsForYou, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        for (int i = 0; i < data.coupons.length && i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: _DealCard(coupon: data.coupons[i], index: i)),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GreenHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  const _GreenHeader({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 15),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context)!.deliverTo, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      Row(
                        children: [
                          Text(AppLocalizations.of(context)!.home, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),
                const NotificationBell(),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(AppLocalizations.of(context)!.searchForRestaurantOrFood, style: TextStyle(color: Colors.grey.shade500)),
                    ),
                    Icon(Icons.tune, color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> coupons;
  final VoidCallback onOrderNow;
  const _BannerCarousel({required this.coupons, required this.onOrderNow});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.coupons.isEmpty) return;
      final next = (_page + 1) % widget.coupons.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const foodImage = 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=500&h=400&fit=crop';

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.coupons.length,
            itemBuilder: (_, i) {
              final c = widget.coupons[i];
              final isPercent = c['discount_type'] == 'percent';
              final label = isPercent ? '${c['discount_value']}%' : '₹${c['discount_value']}';
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF2A0A08), AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        top: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(foodImage, width: 190, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 20,
                        child: Text(
                          AppLocalizations.of(context)!.goodFoodGoodMood,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontStyle: FontStyle.italic, height: 1.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sell, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(AppLocalizations.of(context)!.limitedTimeOffer, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '$label ', style: const TextStyle(color: AppTheme.gold, fontSize: 30, fontWeight: FontWeight.w900)),
                                  TextSpan(text: AppLocalizations.of(context)!.offSuffix, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(AppLocalizations.of(context)!.useCode(c['code'].toString()), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: widget.onOrderNow,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                                decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(AppLocalizations.of(context)!.orderNow, style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward, color: AppTheme.primaryDark, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.coupons.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.coupons.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppTheme.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List categories;
  const _CategoryRow({required this.categories});

  static const _fallbackIcons = [Icons.rice_bowl, Icons.local_pizza, Icons.lunch_dining, Icons.cake, Icons.icecream, Icons.local_drink];

  @override
  Widget build(BuildContext context) {
    final shown = categories.take(8).toList();
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length + 1, // +1 for the trailing "More" tile
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, i) {
          if (i == shown.length) {
            return _CategoryItem(
              label: AppLocalizations.of(context)!.more,
              icon: null,
              fallbackIcon: Icons.grid_view_rounded,
              isMore: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantListScreen())),
            );
          }
          return _CategoryItem(
            label: shown[i].displayName(context),
            icon: shown[i].icon,
            fallbackIcon: _fallbackIcons[i % _fallbackIcons.length],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RestaurantListScreen(initialQuery: shown[i].name)),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String? icon;
  final IconData fallbackIcon;
  final bool isMore;
  final VoidCallback onTap;
  const _CategoryItem({required this.label, required this.icon, required this.fallbackIcon, required this.onTap, this.isMore = false});

  static const _accentColors = [AppTheme.primary, Color(0xFF2E7D32), Color(0xFFF7B500), AppTheme.primary, Color(0xFF2E7D32)];

  @override
  Widget build(BuildContext context) {
    // Cheap stable "random" accent so the same category always gets the
    // same ring/underline color across rebuilds, without needing the
    // list index threaded all the way down here.
    final accent = isMore ? AppTheme.primary : _accentColors[label.hashCode.abs() % _accentColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 2)),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: isMore ? AppTheme.primary : AppTheme.surface(context),
              backgroundImage: icon != null ? NetworkImage(icon!) : null,
              child: icon == null
                  ? Icon(fallbackIcon, color: isMore ? Colors.white : accent, size: 22)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Container(width: 20, height: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

class _HomeRestaurantCard extends StatefulWidget {
  final dynamic restaurant;
  final VoidCallback onTap;
  const _HomeRestaurantCard({required this.restaurant, required this.onTap});

  @override
  State<_HomeRestaurantCard> createState() => _HomeRestaurantCardState();
}

class _HomeRestaurantCardState extends State<_HomeRestaurantCard> {
  late bool _liked = widget.restaurant.likedByMe;
  bool _toggling = false;

  Future<void> _toggleLike() async {
    if (_toggling) return;
    setState(() { _toggling = true; _liked = !_liked; });
    try {
      final (liked, _) = await CustomerService.toggleLike(widget.restaurant.id);
      if (mounted) setState(() => _liked = liked);
    } catch (_) {
      if (mounted) setState(() => _liked = !_liked);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop';

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    restaurant.image?.isNotEmpty == true ? restaurant.image! : fallbackImage,
                    height: 120,
                    width: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(fallbackImage, height: 120, width: 190, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: _toggleLike,
                    child: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? Colors.green.shade600 : Colors.white,
                      size: 22,
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 11, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      restaurant.distanceKm != null
                          ? '${restaurant.distanceKm.toStringAsFixed(1)} km'
                          : AppLocalizations.of(context)!.prepTimeRange(restaurant.prepTimeMin.toString(), restaurant.prepTimeMax.toString()),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(restaurant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(restaurant.cuisine ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(
                  AppLocalizations.of(context)!.prepTimeRange(restaurant.prepTimeMin.toString(), restaurant.prepTimeMax.toString()),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                Text('  |  ', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                Icon(Icons.sell_outlined, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.forTwo(restaurant.costForTwo.toString()),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewAllPill extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.primary, size: 11),
          ],
        ),
      ),
    );
  }
}

class _PopularItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const _PopularItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    item.image?.isNotEmpty == true ? item.image! : fallbackImage,
                    height: 110,
                    width: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(fallbackImage, height: 110, width: 150, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700, width: 1.4),
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700),
                      ),
                    ),
                  ),
                ),
                if (item.rating > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            if (item.restaurantName != null)
              Text(item.restaurantName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
            const SizedBox(height: 2),
            Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.success, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final int index;
  const _DealCard({required this.coupon, required this.index});

  static const _bgColors = [Color(0xFFFBDADA), Color(0xFFFFF3D0), Color(0xFFFDF6EC)];
  static const _icons = [Icons.delivery_dining, Icons.local_pizza, Icons.account_balance_wallet];

  @override
  Widget build(BuildContext context) {
    final isPercent = coupon['discount_type'] == 'percent';
    final label = isPercent ? 'Flat ${coupon['discount_value']}% OFF' : '₹${coupon['discount_value']} OFF';
    final color = _bgColors[index % _bgColors.length];
    final icon = _icons[index % _icons.length];

    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This card's background is a fixed pastel accent color (not
          // theme-aware - see _bgColors), so its text must stay dark
          // regardless of app theme, unlike most text elsewhere in this
          // screen which follows the theme's default color.
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.codeLabel(coupon['code'].toString()), style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5)),
          const Spacer(),
          Align(alignment: Alignment.bottomRight, child: Icon(icon, color: AppTheme.primaryDark.withOpacity(0.6), size: 30)),
        ],
      ),
    );
  }
}
