import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class PremiumRestaurantWidget extends StatelessWidget {
  final List<RestaurantModel> restaurants;
  final Function(RestaurantModel) onRestaurantTap;

  const PremiumRestaurantWidget({
    Key? key,
    required this.restaurants,
    required this.onRestaurantTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final premiumRestaurants =
        restaurants.where((restaurant) => restaurant.isPremium).toList();

    if (premiumRestaurants.isEmpty) return const SizedBox.shrink();

    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              localizations.premiumRestaurants,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: premiumRestaurants.length,
              itemBuilder: (context, index) {
                return _PremiumRestaurantCard(
                  restaurant: premiumRestaurants[index],
                  onTap: () => onRestaurantTap(premiumRestaurants[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumRestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const _PremiumRestaurantCard({
    Key? key,
    required this.restaurant,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = restaurant.imageUrl;
    final distance = restaurant.distance;
    final deliveryTime =
        '${restaurant.deliveryMin}-${restaurant.deliveryMax} min';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColorApp.textBlack,
                          fontSize: 16,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SvgPicture.asset(
                        MediaRes.timeIcon,
                        width: 14,
                        height: 14,
                        color: ColorApp.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distance != null
                            ? '${distance.toStringAsFixed(1)} km - $deliveryTime'
                            : deliveryTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColorApp.grey,
                              fontSize: 12,
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 140,
      width: double.infinity,
      color: ColorApp.primary.withOpacity(0.1),
      child: const Icon(Icons.restaurant, size: 40, color: ColorApp.primary),
    );
  }
}
