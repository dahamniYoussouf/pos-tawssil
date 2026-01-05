import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurants_by_category_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';

class CategoryChipsList extends StatelessWidget {
  final List<HomeCategoryModel> categories;
  final List<RestaurantModel>? allRestaurants;
  final bool hideText;

  const CategoryChipsList({
    Key? key,
    required this.categories,
    this.allRestaurants,
    this.hideText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!hideText)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.categories,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: 0.0,
                        color: ColorApp.textBlack,
                      ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map((category) => _buildCategoryChip(category, context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(HomeCategoryModel category, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantsByCategoryPage(
              category: category,
              initialRestaurants: allRestaurants,
            ),
          ),
        );
      },
      child: Container(
        // height: 84,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              category.imageUrl ?? '',
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: ColorApp.primary,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorApp.textBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
