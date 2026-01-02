import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:client_app/src/features/restaurant/pages/restaurants_by_category_page.dart';

import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class ThematicSelectionsSection extends StatelessWidget {
  final List<ThematicSelectionModel> selections;
  final Function(ThematicSelectionModel) onSelectionTap;
  final List<RestaurantModel> allRestaurants;

  const ThematicSelectionsSection({
    Key? key,
    required this.selections,
    required this.onSelectionTap,
    required this.allRestaurants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selections.isEmpty) return const SizedBox.shrink();
    final activeSelections = selections
        .where((s) => s.isActive && s.restaurants.isNotEmpty)
        .toList();
    if (activeSelections.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: activeSelections
            .map((selection) => _ThematicSelectionItem(
                  selection: selection,
                  onSelectionTap: () => onSelectionTap(selection),
                  allRestaurants: allRestaurants,
                  onRestaurantTap: (restaurant) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailsPage(
                          restaurant: restaurant,
                        ),
                      ),
                    );
                  },
                ))
            .toList(),
      ),
    );
  }
}

class _ThematicSelectionItem extends StatelessWidget {
  final ThematicSelectionModel selection;
  final VoidCallback onSelectionTap;
  final Function(RestaurantModel) onRestaurantTap;
  final List<RestaurantModel> allRestaurants;
  const _ThematicSelectionItem({
    Key? key,
    required this.selection,
    required this.onSelectionTap,
    required this.onRestaurantTap,
    required this.allRestaurants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selection.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: ColorApp.textBlack,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantsByCategoryPage(
                        category: null,
                        initialRestaurants: allRestaurants,
                      ),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.showAll,
                  style: TextStyle(
                    color: ColorApp.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: selection.restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = selection.restaurants[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: _ThematicSelectionCard(
                  restaurant: restaurant,
                  onTap: () => onRestaurantTap(restaurant),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThematicSelectionCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const _ThematicSelectionCard({
    Key? key,
    required this.restaurant,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              child: Image.network(
                restaurant.imageUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderImage(),
              ),
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
                      // todo : add Distance and time from the restaurant to the user
                      Text(
                        '2.5 km - 20 min',
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
      height: 130,
      width: double.infinity,
      color: ColorApp.primary.withOpacity(0.1),
      child: const Icon(Icons.local_offer, size: 40, color: ColorApp.primary),
    );
  }
}
