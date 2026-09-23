import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/customer_service.dart';
import '../../models/menu_item.dart';
import '../../theme.dart';
import '../restaurant/restaurant_menu_screen.dart';
import '../restaurant/restaurant_list_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/notification_bell.dart';
import '../../l10n/app_localizations.dart';
import '../../services/cart_service.dart';
import '../../models/cart_item.dart';
import '../../state/app_state.dart';
import '../../utils/cart_restaurant_guard.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/animations.dart';

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
    setState(() {
      _future = CustomerService.home();
    });
    await _future;
  }

  void _browseAll() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RestaurantListScreen(),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.scaffoldBg(context),
        body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _refresh,
        child: FutureBuilder<HomeData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _HomeLoading();
            }

            if (snap.hasError) {
              return _HomeError(
                message: AppLocalizations.of(context)!
                    .couldNotLoadHome(snap.error.toString()),
                onRetry: _refresh,
              );
            }

            if (!snap.hasData) {
              return _HomeError(
                message: 'Unable to load home data',
                onRetry: _refresh,
              );
            }

            final data = snap.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _ModernHeader(
                  onSearchTap: _openSearch,
                ),

                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.banners.isNotEmpty)
                          _ModernBannerCarousel(
                            banners: data.banners,
                            onBrowseAll: _browseAll,
                          ),

                        if (data.banners.isNotEmpty)
                          const SizedBox(height: 26),

                        if (data.categories.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Explore Categories',
                            onTap: _browseAll,
                          ),
                          const SizedBox(height: 14),
                          _ModernCategoryRow(
                            categories: data.categories,
                          ),
                        ],

                        const SizedBox(height: 28),

                        if (data.nearbyStores.isNotEmpty) ...[
                          _LocationSectionHeader(
                            onTap: _browseAll,
                          ),
                          const SizedBox(height: 14),
                          _RestaurantHorizontalList(
                            restaurants: data.nearbyStores,
                          ),
                        ],

                        const SizedBox(height: 30),

                        _SectionHeader(
                          title: AppLocalizations.of(context)!
                              .popularRestaurants,
                          onTap: _browseAll,
                        ),

                        const SizedBox(height: 14),

                        _RestaurantHorizontalList(
                          restaurants: data.restaurants,
                        ),

                        if (data.newRestaurants.isNotEmpty) ...[
                          const SizedBox(height: 32),

                          _SectionHeader(
                            title: 'New Restaurants',
                            onTap: _browseAll,
                          ),

                          const SizedBox(height: 14),

                          _RestaurantHorizontalList(
                            restaurants: data.newRestaurants,
                            isNew: true,
                          ),
                        ],

                        if (data.popularItems.isNotEmpty) ...[
                          const SizedBox(height: 32),

                          _SectionHeader(
                            title:
                                AppLocalizations.of(context)!.popularItems,
                            onTap: _browseAll,
                          ),

                          const SizedBox(height: 14),

                          _PopularFoodList(
                            items: data.popularItems,
                          ),
                        ],


                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ============================================================
   HEADER
============================================================ */

class _ModernHeader extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _ModernHeader({
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 48),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.deliverTo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Text(
                            l10n.home,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
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
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.shadowElevated(context),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary(context),
                      size: 23,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        l10n.searchForRestaurantOrFood,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
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

/* ============================================================
   SECTION HEADER
============================================================ */

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary(context),
              letterSpacing: -0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.viewAll,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   LOCATION HEADER
============================================================ */

class _LocationSectionHeader extends StatelessWidget {
  final VoidCallback onTap;

  const _LocationSectionHeader({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary.withOpacity(.16), AppTheme.primary.withOpacity(.07)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: const Icon(
            Icons.near_me_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.nearbyStores,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.nearbyStoresSubtitle,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(.09),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.primary,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   BANNER
============================================================ */

class _ModernBannerCarousel extends StatefulWidget {
  // Admin/restaurant-manager-uploaded banners (Admin\HomeBannerController,
  // customer app reads them from home()'s `banners` key) — each has
  // image/title, and optionally restaurant_id+restaurant_name when it's a
  // specific restaurant's own banner rather than an app-wide one.
  final List<Map<String, dynamic>> banners;
  final VoidCallback onBrowseAll;

  const _ModernBannerCarousel({
    required this.banners,
    required this.onBrowseAll,
  });

  @override
  State<_ModernBannerCarousel> createState() =>
      _ModernBannerCarouselState();
}

class _ModernBannerCarouselState
    extends State<_ModernBannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();

    _controller = PageController();

    if (widget.banners.length > 1) {
      _timer = Timer.periodic(
        const Duration(seconds: 4),
        (_) {
          if (!mounted || widget.banners.isEmpty) return;

          final next =
              (_page + 1) % widget.banners.length;

          _controller.animateToPage(
            next,
            duration:
                const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openBanner(Map<String, dynamic> banner) {
    final restaurantId = banner['restaurant_id'];
    if (restaurantId != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RestaurantMenuScreen(restaurantId: (restaurantId as num).toInt()),
      ));
    } else {
      widget.onBrowseAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) {
              setState(() => _page = i);
            },
            itemBuilder: (_, index) {
              final banner = widget.banners[index];
              final imageUrl = banner['image']?.toString();
              final title = banner['title']?.toString();
              final restaurantName = banner['restaurant_name']?.toString();
              final couponCode = banner['coupon_code']?.toString();
              final discountType = banner['discount_type']?.toString();
              final discountValue = banner['discount_value']?.toString();
              final discountLabel = (couponCode != null && couponCode.isNotEmpty && discountValue != null)
                  ? (discountType == 'percent' ? '$discountValue% OFF' : '₹$discountValue OFF')
                  : null;

              return GestureDetector(
                onTap: () => _openBanner(banner),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(22),
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF164A2A),
                        AppTheme.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(.12),
                        blurRadius: 15,
                        offset:
                            const Offset(0, 7),
                      ),
                    ],
                  ),
                  clipBehavior:
                      Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Full-width banner image — no blank half.
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.expand(),
                        ),

                      // Dark gradient at the bottom keeps the title
                      // readable over any photo without hiding all of it.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(.65),
                                Colors.black.withOpacity(.0),
                              ],
                              stops: const [0, 0.6],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (discountLabel != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  discountLabel,
                                  style: const TextStyle(color: AppTheme.primaryDark, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            if (title != null && title.isNotEmpty)
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                            if (restaurantName != null && restaurantName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                restaurantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.85),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (couponCode != null && couponCode.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Use code $couponCode at checkout',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.85),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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

        if (widget.banners.length > 1)
          Padding(
            padding:
                const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (i) {
                  final active = i == _page;

                  return AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 220,
                    ),
                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    width: active ? 20 : 6,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color: active
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/* ============================================================
   CATEGORY
============================================================ */

class _ModernCategoryRow extends StatelessWidget {
  final List categories;

  const _ModernCategoryRow({
    required this.categories,
  });

  static const _fallbackIcons = [
    Icons.rice_bowl_rounded,
    Icons.local_pizza_rounded,
    Icons.lunch_dining_rounded,
    Icons.cake_rounded,
    Icons.icecream_rounded,
    Icons.local_drink_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final shown =
        categories.take(8).toList();

    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 15),
        itemBuilder: (_, i) {
          if (i == shown.length) {
            return FadeSlideIn(
              index: i,
              child: _ModernCategoryItem(
                label:
                    AppLocalizations.of(context)!
                        .more,
                icon: null,
                fallbackIcon:
                    Icons.grid_view_rounded,
                isMore: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const RestaurantListScreen(),
                    ),
                  );
                },
              ),
            );
          }

          return FadeSlideIn(
            index: i,
            child: _ModernCategoryItem(
              label:
                  shown[i].displayName(context),
              icon: shown[i].icon,
              fallbackIcon:
                  _fallbackIcons[
                      i %
                          _fallbackIcons.length],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RestaurantListScreen(
                      initialQuery:
                          shown[i].name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ModernCategoryItem extends StatelessWidget {
  final String label;
  final String? icon;
  final IconData fallbackIcon;
  final bool isMore;
  final VoidCallback onTap;

  const _ModernCategoryItem({
    required this.label,
    required this.icon,
    required this.fallbackIcon,
    required this.onTap,
    this.isMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isMore
                      ? [
                          AppTheme.primary,
                          AppTheme.primaryDark,
                        ]
                      : [
                          AppTheme.primary
                              .withOpacity(.18),
                          AppTheme.primary
                              .withOpacity(.04),
                        ],
                ),
                boxShadow: isMore ? AppTheme.shadowColored(AppTheme.primary, opacity: 0.3, blur: 14, offset: const Offset(0, 6)) : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppTheme.surface(context),
                ),
                child: ClipOval(
                  child: icon != null
                      ? Image.network(
                          icon!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  Icon(
                            fallbackIcon,
                            color:
                                AppTheme.primary,
                          ),
                        )
                      : Icon(
                          fallbackIcon,
                          color: isMore
                              ? Colors.white
                              : AppTheme.primary,
                          size: 23,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   RESTAURANT LIST
============================================================ */

class _RestaurantHorizontalList extends StatelessWidget {
  final List restaurants;
  final bool isNew;

  const _RestaurantHorizontalList({
    required this.restaurants,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Tall enough for RestaurantCard's full content at width:205 -
      // image + logo row + rating row + price row + veg-pill/View-Menu
      // row. Was 258 (sized for the older, shorter card design), which
      // silently clipped the bottom row off.
      height: 330,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.only(
          right: 2,
        ),
        itemCount: restaurants.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 15),
        itemBuilder: (_, i) {
          final restaurant =
              restaurants[i];

          return FadeSlideIn(
            index: i,
            child: RestaurantCard(
              restaurant: restaurant,
              isNew: isNew,
              width: 225,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RestaurantMenuScreen(
                      restaurantId:
                          restaurant.id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


/* ============================================================
   POPULAR FOOD
============================================================ */

class _PopularFoodList extends StatefulWidget {
  final List<MenuItem> items;
  const _PopularFoodList({required this.items});
  @override State<_PopularFoodList> createState() => _PopularFoodListState();
}

class _PopularFoodListState extends State<_PopularFoodList> {
  final Map<int, int> _qty = {};
  final Set<int> _busy = {};
  int? _lastObservedCartVersion;

  @override void initState() { super.initState(); _loadCart(); }

  // This widget lives inside RootShell's IndexedStack, so it's never
  // disposed/recreated when the user switches away to another tab or
  // pushes a different restaurant's menu on top - initState() above
  // only ever runs once. Without this, adding/resetting the cart from
  // anywhere other than this exact list (a different restaurant's menu
  // screen, search, Cart tab) would leave _qty showing stale items
  // indefinitely, with +/- controls pointing at cart_item_ids that
  // don't exist anymore. AppState.cartVersion (see its own doc
  // comment) bumps on every cart mutation from anywhere in the app, so
  // watching it here keeps this list correct even while it's the tab
  // *not* currently on screen.
  void _syncWithAppState(int cartVersion) {
    if (_lastObservedCartVersion == cartVersion) return;
    _lastObservedCartVersion = cartVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    try {
      final cart = await CartService.view();
      if (!mounted) return;
      setState(() {
        // Replace the local map with the server cart. Do not merge it.
        // After a restaurant reset, old menu-item quantities must disappear
        // immediately; otherwise Popular Items keeps showing stale controls.
        _qty.clear();
        for (final item in cart.items) {
          _qty[item.menuItemId] = item.quantity;
        }
      });
    } catch (_) {}
  }

  Future<void> _add(MenuItem item) async {
    if (_busy.contains(item.id)) return;
    setState(() => _busy.add(item.id));
    try {
      final ok = await CartRestaurantGuard.add(context, menuItemId: item.id, restaurantId: item.restaurantId);
      if (ok) {
        await _loadCart();
        if (mounted) context.read<AppState>().refreshCartCount();
      }
    } finally { if (mounted) setState(() => _busy.remove(item.id)); }
  }

  Future<void> _change(MenuItem item, int delta) async {
    final current = _qty[item.id] ?? 0;
    if (current <= 0) return;
    setState(() => _busy.add(item.id));
    try {
      final cart = await CartService.view();
      CartItem? row;
      for (final x in cart.items) {
        if (x.menuItemId == item.id) { row = x; break; }
      }
      if (row != null) {
        await CartService.updateQuantity(cartItemId: row.id, quantity: current + delta);
        await _loadCart();
        if (mounted) context.read<AppState>().refreshCartCount();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update cart: $e')));
    } finally { if (mounted) setState(() => _busy.remove(item.id)); }
  }

  @override Widget build(BuildContext context) {
    _syncWithAppState(context.watch<AppState>().cartVersion);
    return SizedBox(
      height: 245,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final item = widget.items[i];
          final q = _qty[item.id] ?? 0;
          return FadeSlideIn(
            key: ValueKey(item.id),
            index: i,
            child: _ModernFoodCard(
              item: item,
              quantity: q,
              busy: _busy.contains(item.id),
              onAdd: () => _add(item),
              onDecrease: () => _change(item, -1),
              onIncrease: () => _change(item, 1),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurantId: item.restaurantId))),
            ),
          );
        },
      ),
    );
  }
}

class _ModernFoodCard
    extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  final int quantity;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _ModernFoodCard({required this.item, required this.onTap, required this.quantity, required this.busy, required this.onAdd, required this.onDecrease, required this.onIncrease});

  @override
  Widget build(BuildContext context) {
    const fallbackImage =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&h=400&fit=crop';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    AppTheme.radiusLg,
                  ),
                  child: Image.network(
                    item.image?.isNotEmpty ==
                            true
                        ? item.image!
                        : fallbackImage,
                    height: 125,
                    width: 160,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                            Image.network(
                      fallbackImage,
                      height: 125,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  left: 8,
                  child: _VegBadge(
                    isVeg: item.isVeg,
                  ),
                ),

                if (item.rating > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          7,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color:
                                Color(0xFFFFB300),
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Text(
                            item.rating
                                .toStringAsFixed(
                              1,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 9.5,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              item.name,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight:
                    FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),

            // Cart controls must not depend on restaurantName being present.
            // The popular-items API can return a menu item without the optional
            // restaurantName field, but restaurantId is still available for the
            // cart guard.
            if (quantity == 0)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 34,
                  child: IconButton.filled(
                    onPressed: busy ? null : onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    padding: EdgeInsets.zero,
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: busy
                    ? const SizedBox(
                        width: 80,
                        height: 34,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : QuantityStepper(
                        quantity: quantity,
                        onDecrease: onDecrease,
                        onIncrease: onIncrease,
                        compact: true,
                      ),
              ),

            const SizedBox(height: 2),
            if (item.restaurantName != null)
              Text(
                item.restaurantName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 10.5,
                ),
              ),

            const SizedBox(height: 4),

            Text(
              '₹${item.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VegBadge extends StatelessWidget {
  final bool isVeg;

  const _VegBadge({
    required this.isVeg,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVeg
        ? Colors.green.shade700
        : Colors.red.shade700;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(5),
        border: Border.all(
          color: color,
          width: 1.3,
        ),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   DEALS
============================================================ */

class _DealsList extends StatelessWidget {
  final List<Map<String, dynamic>> coupons;

  const _DealsList({
    required this.coupons,
  });

  @override
  Widget build(BuildContext context) {
    final count =
        coupons.length > 3
            ? 3
            : coupons.length;

    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (_, i) {
          return FadeSlideIn(
            index: i,
            child: _ModernDealCard(
              coupon: coupons[i],
              index: i,
            ),
          );
        },
      ),
    );
  }
}

class _ModernDealCard
    extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final int index;

  const _ModernDealCard({
    required this.coupon,
    required this.index,
  });

  static const _icons = [
    Icons.delivery_dining_rounded,
    Icons.local_pizza_rounded,
    Icons.account_balance_wallet_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isPercent =
        coupon['discount_type'] ==
            'percent';

    final label = isPercent
        ? '${coupon['discount_value']}% OFF'
        : '₹${coupon['discount_value']} OFF';

    return Container(
      width: 190,
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(AppTheme.radiusLg),
        gradient: LinearGradient(
          colors: [
            AppTheme.primary
                .withOpacity(.12),
            AppTheme.primary
                .withOpacity(.035),
          ],
        ),
        border: Border.all(
          color: AppTheme.primary
              .withOpacity(.10),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  gradient:
                      AppTheme.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(
                    AppTheme.radiusSm,
                  ),
                  boxShadow: AppTheme.shadowColored(AppTheme.primary, opacity: 0.25, blur: 10, offset: const Offset(0, 3)),
                ),
                child: Text(
                  label,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 9),

              Text(
                AppLocalizations.of(
                  context,
                )!.codeLabel(
                  coupon['code']
                      .toString(),
                ),
                style: TextStyle(
                  color:
                      AppTheme.textPrimary(context),
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                'Use this offer on your next order',
                maxLines: 2,
                style: TextStyle(
                  color:
                      AppTheme.textSecondary(context),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),

          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              _icons[
                  index %
                      _icons.length],
              size: 32,
              color: AppTheme.primary
                  .withOpacity(.45),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   LOADING
============================================================ */

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          height: 210,
          decoration:
              const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        Transform.translate(
          offset:
              const Offset(0, -25),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: Column(
              children: [
                _SkeletonBox(
                  height: 190,
                  radius: 22,
                ),
                const SizedBox(
                    height: 25),
                Row(
                  children: List.generate(
                    4,
                    (_) => Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          right: 10,
                        ),
                        child:
                            _SkeletonBox(
                          height: 72,
                          radius: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                    height: 30),
                const _SkeletonBox(
                  height: 220,
                  radius: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox
    extends StatelessWidget {
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius:
            BorderRadius.circular(radius),
      ),
    );
  }
}

/* ============================================================
   ERROR
============================================================ */

class _HomeError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _HomeError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              height: 75,
              width: 75,
              decoration:
                  BoxDecoration(
                color: AppTheme.primary
                    .withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .cloud_off_rounded,
                color:
                    AppTheme.primary,
                size: 34,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    AppTheme.textSecondary(context),
                fontSize: 12.5,
              ),
            ),

            const SizedBox(height: 18),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowColored(AppTheme.primary),
              ),
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Try Again',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      AppTheme.radiusLg,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}