import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

class RestaurantListTile extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const RestaurantListTile({super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&h=200&fit=crop';

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: restaurant.isOpen ? 1 : 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      restaurant.image?.isNotEmpty == true ? restaurant.image! : fallbackImage,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(fallbackImage, width: 64, height: 64, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.white),
                          const SizedBox(width: 1),
                          Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
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
                    Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      [restaurant.cuisine, if (!restaurant.isOpen) AppLocalizations.of(context)!.closedLabel].where((e) => (e ?? '').isNotEmpty).join(' • '),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.prepTimeAndCost(
                        restaurant.prepTimeMin.toString(),
                        restaurant.prepTimeMax.toString(),
                        restaurant.costForTwo.toString(),
                      ),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (restaurant.discountLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                  child: Text(restaurant.discountLabel!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
