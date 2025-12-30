import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';

import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/restaurant/widgets/restaurant_card.dart';

class ThematicSelectionsSection extends StatelessWidget {
  final List<ThematicSelectionModel> selections;
  final Function(ThematicSelectionModel) onSelectionTap;

  const ThematicSelectionsSection({
    Key? key,
    required this.selections,
    required this.onSelectionTap,
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

  const _ThematicSelectionItem({
    Key? key,
    required this.selection,
    required this.onSelectionTap,
    required this.onRestaurantTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                onPressed: onSelectionTap,
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
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: selection.restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = selection.restaurants[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: RestaurantCard(
                  restaurant: restaurant,
                  onTap: () => onRestaurantTap(restaurant),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
