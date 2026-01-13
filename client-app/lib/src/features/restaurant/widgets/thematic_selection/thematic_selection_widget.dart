import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:client_app/src/features/restaurant/pages/restaurants_by_category_page.dart';
import 'package:client_app/src/features/restaurant/widgets/thematic_selection/thematic_card.dart';

import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/l10n/app_localizations.dart';

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
        .where((s) => s.isActive && s.restaurantIds.isNotEmpty)
        .toList();
    if (activeSelections.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(MediaRes.thematicBackgroundImage),
          fit: BoxFit.cover,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThematicBar(context),
          ...activeSelections
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
        ],
      ),
    );
  }

  Widget _buildThematicBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      child: Image.asset(MediaRes.thematicBarImage, fit: BoxFit.cover),
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
    // Get restaurants from allRestaurants by matching IDs
    final restaurants = selection.restaurantIds
        .map((id) {
          final found =
              allRestaurants.where((restaurant) => restaurant.id == id);
          return found.isEmpty ? null : found.first;
        })
        .whereType<RestaurantModel>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selection.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: ColorApp.textBlack,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantsByCategoryPage(
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
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return ThematicSelectionCard(
                restaurant: restaurant,
                onTap: () => onRestaurantTap(restaurant),
              );
            },
          ),
        ),
      ],
    );
  }
}
