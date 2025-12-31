import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/l10n/app_localizations.dart';

class RecommendedDishesWidget extends StatelessWidget {
  final List<RecommendedDishModel> dishes;
  final Function(RecommendedDishModel) onDishTap;

  const RecommendedDishesWidget({
    Key? key,
    required this.dishes,
    required this.onDishTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeDishes = dishes.where((d) => d.isActive).toList();

    if (activeDishes.isEmpty) return const SizedBox.shrink();

    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              localizations.recommendedDishes,
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
              itemCount: activeDishes.length,
              itemBuilder: (context, index) {
                return _RecommendedDishCard(
                  dish: activeDishes[index],
                  onTap: () => onDishTap(activeDishes[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedDishCard extends StatelessWidget {
  final RecommendedDishModel dish;
  final VoidCallback onTap;

  const _RecommendedDishCard({
    Key? key,
    required this.dish,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = dish.menuItem?.photoUrl;
    final dishName = dish.menuItem?.nom ?? '';
    final restaurantName = dish.restaurant?.name;

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
              child: imageUrl != null && imageUrl.isNotEmpty
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
                    dishName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColorApp.textBlack,
                          fontSize: 16,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (restaurantName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurantName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorApp.grey,
                            fontSize: 12,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
      height: 130,
      width: double.infinity,
      color: ColorApp.primary.withOpacity(0.1),
      child:
          const Icon(Icons.restaurant_menu, size: 40, color: ColorApp.primary),
    );
  }
}
