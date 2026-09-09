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
      backgroundColor: AppTheme.surface(context),
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
                        if (data.coupons.isNotEmpty)
                          _ModernBannerCarousel(
                            coupons: data.coupons,
                            onOrderNow: _browseAll,
                          ),

                        if (data.coupons.isNotEmpty)
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

                        if (data.coupons.isNotEmpty) ...[
                          const SizedBox(height: 32),

                          _SectionHeader(
                            title:
                                AppLocalizations.of(context)!.bestDealsForYou,
                            onTap: () {},
                          ),

                          const SizedBox(height: 14),

                          _DealsList(
                            coupons: data.coupons,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade500,
                      size: 23,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        l10n.searchForRestaurantOrFood,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primary,
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
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
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
            color: AppTheme.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.nearbyStoresSubtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
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
              borderRadius: BorderRadius.circular(20),
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
  final List<Map<String, dynamic>> coupons;
  final VoidCallback onOrderNow;

  const _ModernBannerCarousel({
    required this.coupons,
    required this.onOrderNow,
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

    if (widget.coupons.length > 1) {
      _timer = Timer.periodic(
        const Duration(seconds: 4),
        (_) {
          if (!mounted || widget.coupons.isEmpty) return;

          final next =
              (_page + 1) % widget.coupons.length;

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

  @override
  Widget build(BuildContext context) {
    const foodImage =
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop';

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.coupons.length,
            onPageChanged: (i) {
              setState(() => _page = i);
            },
            itemBuilder: (_, index) {
              final coupon =
                  widget.coupons[index];

              final isPercent =
                  coupon['discount_type'] ==
                      'percent';

              final label = isPercent
                  ? '${coupon['discount_value']}%'
                  : '₹${coupon['discount_value']}';

              return Container(
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
                  children: [
                    Positioned(
                      right: -25,
                      top: -10,
                      bottom: -10,
                      child: Opacity(
                        opacity: .95,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                          child: Image.network(
                            foodImage,
                            width: 190,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: DecoratedBox(
                        decoration:
                            BoxDecoration(
                          gradient:
                              LinearGradient(
                            colors: [
                              Colors.black
                                  .withOpacity(.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        16,
                      ),
                      child: Column(
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
                              color: Colors.white
                                  .withOpacity(.16),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: const Text(
                              'LIMITED OFFER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight:
                                    FontWeight.w800,
                                letterSpacing: .6,
                              ),
                            ),
                          ),

                          const Spacer(),

                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$label ',
                                  style:
                                      const TextStyle(
                                    color:
                                        AppTheme.gold,
                                    fontSize: 30,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      AppLocalizations
                                          .of(context)!
                                          .offSuffix,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 27,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            AppLocalizations.of(
                              context,
                            )!.useCode(
                              coupon['code']
                                  .toString(),
                            ),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap:
                                widget.onOrderNow,
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    AppTheme.gold,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations
                                        .of(context)!
                                        .orderNow,
                                    style:
                                        const TextStyle(
                                      color: AppTheme
                                          .primaryDark,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  const Icon(
                                    Icons
                                        .arrow_forward_rounded,
                                    color: AppTheme
                                        .primaryDark,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        if (widget.coupons.length > 1)
          Padding(
            padding:
                const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: List.generate(
                widget.coupons.length,
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
            return _ModernCategoryItem(
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
            );
          }

          return _ModernCategoryItem(
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
    return GestureDetector(
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
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
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

  const _RestaurantHorizontalList({
    required this.restaurants,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 258,
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

          return _ModernRestaurantCard(
            restaurant: restaurant,
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
          );
        },
      ),
    );
  }
}

class _ModernRestaurantCard
    extends StatefulWidget {
  final dynamic restaurant;
  final VoidCallback onTap;

  const _ModernRestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  State<_ModernRestaurantCard>
      createState() =>
          _ModernRestaurantCardState();
}

class _ModernRestaurantCardState
    extends State<_ModernRestaurantCard> {
  late bool _liked =
      widget.restaurant.likedByMe;

  bool _toggling = false;

  Future<void> _toggleLike() async {
    if (_toggling) return;

    setState(() {
      _toggling = true;
      _liked = !_liked;
    });

    try {
      final result =
          await CustomerService.toggleLike(
        widget.restaurant.id,
      );

      if (mounted) {
        setState(() {
          _liked = result.$1;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _toggling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant =
        widget.restaurant;

    const fallbackImage =
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&h=400&fit=crop';

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 205,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    17,
                  ),
                  child: Image.network(
                    restaurant.image
                                ?.isNotEmpty ==
                            true
                        ? restaurant.image!
                        : fallbackImage,
                    height: 132,
                    width: 205,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                            Image.network(
                      fallbackImage,
                      height: 132,
                      width: 205,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                  top: 9,
                  left: 9,
                  child: GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration:
                          BoxDecoration(
                        color: Colors.black
                            .withOpacity(.38),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _liked
                            ? Icons
                                .favorite_rounded
                            : Icons
                                .favorite_border_rounded,
                        color: _liked
                            ? Colors.redAccent
                            : Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color:
                              Color(0xFFFFB300),
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        Text(
                          restaurant.rating
                              .toStringAsFixed(
                            1,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 9,
                  left: 9,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.black
                          .withOpacity(.68),
                      borderRadius:
                          BorderRadius.circular(
                        7,
                      ),
                    ),
                    child: Text(
                      restaurant.distanceKm !=
                              null
                          ? '${restaurant.distanceKm.toStringAsFixed(1)} km'
                          : AppLocalizations
                                  .of(context)!
                              .prepTimeRange(
                              restaurant
                                  .prepTimeMin
                                  .toString(),
                              restaurant
                                  .prepTimeMax
                                  .toString(),
                            ),
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            Text(
              restaurant.name,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              restaurant.cuisine ?? '',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.5,
              ),
            ),

            const SizedBox(height: 7),

            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.prepTimeRange(
                    restaurant.prepTimeMin
                        .toString(),
                    restaurant.prepTimeMax
                        .toString(),
                  ),
                  style:
                      const TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 3,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade400,
                    shape:
                        BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.forTwo(
                      restaurant
                          .costForTwo
                          .toString(),
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.primary,
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
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

/* ============================================================
   POPULAR FOOD
============================================================ */

class _PopularFoodList extends StatelessWidget {
  final List<MenuItem> items;

  const _PopularFoodList({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 215,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 14),
        itemBuilder: (_, i) {
          return _ModernFoodCard(
            item: items[i],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      RestaurantMenuScreen(
                    restaurantId:
                        items[i].restaurantId,
                  ),
                ),
              );
            },
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

  const _ModernFoodCard({
    required this.item,
    required this.onTap,
  });

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
                    17,
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
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            if (item.restaurantName != null) ...[
              const SizedBox(height: 2),
              Text(
                item.restaurantName!,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 10.5,
                ),
              ),
            ],

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
          return _ModernDealCard(
            coupon: coupons[i],
            index: i,
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
            BorderRadius.circular(18),
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
                  color:
                      AppTheme.primary,
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
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
                      Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const Spacer(),

              Text(
                'Use this offer on your next order',
                maxLines: 2,
                style: TextStyle(
                  color:
                      Colors.grey.shade700,
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
            gradient: LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.primaryDark,
              ],
            ),
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

            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
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
                    Colors.grey.shade600,
                fontSize: 12.5,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
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
                    12,
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