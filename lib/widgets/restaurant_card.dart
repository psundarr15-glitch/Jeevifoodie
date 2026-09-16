import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/customer_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

/// The one restaurant card design used everywhere a restaurant is shown
/// as a card: home screen's horizontal sections (Nearby/Popular/New),
/// search results, and the full restaurant list. Photo on top (framed
/// with rounded corners, NEW ribbon + like button + prep-time pill),
/// then a white body with the logo, name, rating/cuisine, price, a
/// veg/non-veg pill, and a "View Menu" button.
///
/// Pass [width] for a fixed-width card in a horizontal ListView; leave
/// it null to fill the available width (vertical lists/grids).
class RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final bool isNew;
  final double? width;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.isNew = false,
    this.width,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  late bool _liked = widget.restaurant.likedByMe;
  bool _toggling = false;

  static const _fallbackImage = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&h=400&fit=crop';
  // A dark forest green for the restaurant name — distinct from the
  // app's red/gold brand accent (still used for the NEW ribbon, price,
  // and View Menu button below), matching the target card design.
  static const _nameGreen = Color(0xFF163E2F);
  static const _logoCream = Color(0xFFF3EEDC);

  Future<void> _toggleLike() async {
    if (_toggling) return;
    setState(() {
      _toggling = true;
      _liked = !_liked; // optimistic
    });
    try {
      final (liked, _) = await CustomerService.toggleLike(widget.restaurant.id);
      if (mounted) setState(() => _liked = liked);
    } catch (_) {
      if (mounted) setState(() => _liked = !_liked); // revert on failure
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final t = AppLocalizations.of(context)!;
    final isVeg = restaurant.foodType == 'veg';
    final isNonVeg = restaurant.foodType == 'non_veg';

    final card = Opacity(
      opacity: restaurant.isOpen ? 1 : 0.6,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            color: AppTheme.surface(context),
            boxShadow: AppTheme.shadowSoft(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Stack(
                    children: [
                      Image.network(
                        restaurant.image?.isNotEmpty == true ? restaurant.image! : _fallbackImage,
                        height: 148,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.network(_fallbackImage, height: 148, width: double.infinity, fit: BoxFit.cover),
                      ),
                      if (widget.isNew)
                        Positioned(
                          top: 12,
                          left: -34,
                          child: Transform.rotate(
                            angle: -0.78539816339, // -45deg
                            child: Container(
                              width: 130,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                boxShadow: AppTheme.shadowColored(AppTheme.primary, opacity: 0.35, blur: 8, offset: const Offset(0, 2)),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: GestureDetector(
                          onTap: _toggleLike,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _liked ? AppTheme.primary : Colors.black54,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 9,
                        bottom: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_filled_rounded, size: 13, color: AppTheme.success),
                              const SizedBox(width: 5),
                              Text(
                                restaurant.distanceKm != null
                                    ? '${restaurant.distanceKm!.toStringAsFixed(1)} km'
                                    : t.prepTimeRange(restaurant.prepTimeMin.toString(), restaurant.prepTimeMax.toString()),
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!restaurant.isOpen)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.4),
                            alignment: Alignment.center,
                            child: Text(
                              t.closedLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      if (restaurant.discountLabel != null)
                        Positioned(
                          right: 9,
                          bottom: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                            child: Text(restaurant.discountLabel!, style: const TextStyle(color: AppTheme.primaryDark, fontSize: 10.5, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: _logoCream, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                          clipBehavior: Clip.antiAlias,
                          child: restaurant.logo?.isNotEmpty == true
                              ? Image.network(restaurant.logo!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_rounded, color: _nameGreen, size: 20))
                              : const Icon(Icons.restaurant_rounded, color: _nameGreen, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: _nameGreen, letterSpacing: -0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.gold, size: 16),
                        const SizedBox(width: 3),
                        Text(restaurant.rating.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                        if ((restaurant.cuisine ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              restaurant.cuisine!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary(context)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.sell_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 5),
                        Text(t.forTwo(restaurant.costForTwo.toString()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (isVeg || isNonVeg)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isVeg ? AppTheme.softGreen : AppTheme.softRed,
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isVeg ? Icons.eco_rounded : Icons.set_meal_rounded, size: 13, color: isVeg ? AppTheme.success : AppTheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  isVeg ? t.vegLabel : t.nonVegLabel,
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: isVeg ? AppTheme.success : AppTheme.primary),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.viewMenu, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
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
      ),
    );

    return widget.width != null ? SizedBox(width: widget.width, child: card) : card;
  }
}
