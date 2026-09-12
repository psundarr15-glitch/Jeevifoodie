import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/customer_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

/// Big grid-style restaurant card — dark photo on top (with a like/heart
/// toggle), name + rating/time + cuisine in a white body below, both
/// halves forming one rounded card.
class RestaurantListTile extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const RestaurantListTile({super.key, required this.restaurant, required this.onTap});

  @override
  State<RestaurantListTile> createState() => _RestaurantListTileState();
}

class _RestaurantListTileState extends State<RestaurantListTile> {
  late bool _liked = widget.restaurant.likedByMe;
  bool _togglingLike = false;

  Future<void> _toggleLike() async {
    if (_togglingLike) return;
    setState(() {
      _togglingLike = true;
      _liked = !_liked; // optimistic
    });
    try {
      final (liked, _) = await CustomerService.toggleLike(widget.restaurant.id);
      if (mounted) setState(() => _liked = liked);
    } catch (_) {
      if (mounted) setState(() => _liked = !_liked); // revert on failure
    } finally {
      if (mounted) setState(() => _togglingLike = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop';

    return Opacity(
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
              Stack(
                children: [
                  Image.network(
                    restaurant.image?.isNotEmpty == true ? restaurant.image! : fallbackImage,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(fallbackImage, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  // Subtle bottom scrim so any overlaid badges stay legible
                  // against bright food photography, without darkening the
                  // whole image.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0), Colors.black.withOpacity(0.28)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.28), shape: BoxShape.circle),
                        child: Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? const Color(0xFF3DDC84) : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (!restaurant.isOpen)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                        child: Text(AppLocalizations.of(context)!.closedLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (restaurant.discountLabel != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          boxShadow: AppTheme.shadowColored(AppTheme.primary, opacity: 0.4, blur: 10, offset: const Offset(0, 3)),
                        ),
                        child: Text(restaurant.discountLabel!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary(context), letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star, color: AppTheme.gold, size: 14),
                            const SizedBox(width: 3),
                            Text(restaurant.rating.toStringAsFixed(1),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary(context)),
                        const SizedBox(width: 3),
                        Text(
                          AppLocalizations.of(context)!.prepTimeRange(restaurant.prepTimeMin.toString(), restaurant.prepTimeMax.toString()),
                          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if ((restaurant.cuisine ?? '').isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        restaurant.cuisine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
