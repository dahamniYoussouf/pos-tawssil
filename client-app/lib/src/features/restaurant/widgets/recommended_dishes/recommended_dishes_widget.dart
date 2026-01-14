import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:client_app/src/features/restaurant/widgets/recommended_dishes/recommended_dishes_card.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/l10n/app_localizations.dart';

class RecommendedDishesWidget extends StatelessWidget {
  final List<RecommendedDishModel> dishes;
  final List<RestaurantModel> allRestaurants;

  const RecommendedDishesWidget({
    Key? key,
    required this.dishes,
    required this.allRestaurants,
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
                return RecommendedDishCard(
                  dish: activeDishes[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailsPage(
                        restaurant: allRestaurants.firstWhere((element) =>
                            element.id == activeDishes[index].restaurantId),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
