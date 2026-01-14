import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:client_app/src/features/restaurant/widgets/annoncements/annoncements_widget.dart';
import 'package:client_app/src/features/restaurant/widgets/category/category_chips_list.dart';
import 'package:client_app/src/features/restaurant/widgets/daily_deals/daily_deals_widget.dart';
import 'package:client_app/src/features/restaurant/widgets/premium_restaurant/premium_restaurant_widget.dart';
import 'package:client_app/src/features/restaurant/widgets/recommended_dishes/recommended_dishes_widget.dart';
import 'package:client_app/src/features/restaurant/widgets/thematic_selection/thematic_selection_widget.dart';
import 'package:flutter/material.dart';
import '../models/homepage_models.dart';
import '../models/restaurant_model.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/restaurant_list_item.dart';

class HomePage extends StatelessWidget {
  final HomepageDataModel homepageData;
  final List<RestaurantModel> allRestaurants;
  final Function(HomeCategoryModel)? onHomeCategoryTap;
  final Function(ThematicSelectionModel)? onThematicSelectionTap;
  final Function(RecommendedDishModel)? onRecommendedDishTap;
  final Function(DailyDealModel)? onDailyDealTap;
  final Function(PromotionModel)? onPromotionTap;

  const HomePage({
    Key? key,
    required this.homepageData,
    required this.allRestaurants,
    this.onHomeCategoryTap,
    this.onThematicSelectionTap,
    this.onRecommendedDishTap,
    this.onDailyDealTap,
    this.onPromotionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (homepageData.homeCategories.isNotEmpty)
            CategoryChipsList(
              categories: homepageData.homeCategories,
              allRestaurants: allRestaurants,
            ),
          if (homepageData.announcements.isNotEmpty)
            AnnouncementsWidget(
              announcements: homepageData.announcements,
            ),
          if (homepageData.dailyDeals.isNotEmpty)
            DailyDealsWidget(
              dailyDeals: homepageData.dailyDeals,
              restaurants: allRestaurants,
              onDealTap: (restaurant) {
                // Handle daily deal tap - navigate to restaurant details or call callback
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailsPage(
                      restaurant: restaurant,
                    ),
                  ),
                );
                // Create a minimal DailyDealModel for callback if needed
                final deal = DailyDealModel(restaurantId: restaurant.id);
                onDailyDealTap?.call(deal);
              },
            ),
          // premium restaurants section (mis en avant)
          if (allRestaurants.isNotEmpty)
            PremiumRestaurantWidget(
                restaurants: allRestaurants, onRestaurantTap: (r) {}),
          Divider(
            color: ColorApp.grey.withOpacity(0.2),
            height: 1,
            thickness: 1,
            endIndent: 20,
            indent: 20,
          ),
          // recommended dishes section
          if (homepageData.recommendedDishes.isNotEmpty)
            RecommendedDishesWidget(
              dishes: homepageData.recommendedDishes,
              onDishTap: onRecommendedDishTap ?? (_) {},
            ),
          if (homepageData.recommendedDishes.isNotEmpty)
            Divider(
              color: ColorApp.grey.withOpacity(0.2),
              height: 1,
              thickness: 1,
              endIndent: 20,
              indent: 20,
            ),
          if (homepageData.thematicSelections.isNotEmpty)
            ThematicSelectionsSection(
              selections: homepageData.thematicSelections,
              onSelectionTap: onThematicSelectionTap ?? (_) {},
              allRestaurants: allRestaurants,
            ),
          Divider(
            color: ColorApp.grey.withOpacity(0.2),
            height: 1,
            thickness: 1,
            endIndent: 20,
            indent: 20,
          ),
          if (allRestaurants.isNotEmpty)
            AllRestaurantsSection(
              restaurants: allRestaurants,
            ),
        ],
      ),
    );
  }
}

class FeaturedRestaurantsSection extends StatelessWidget {
  final List<RestaurantModel> restaurants;

  const FeaturedRestaurantsSection({
    Key? key,
    required this.restaurants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              localizations.featuredRestaurants,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: RestaurantCard(
                    restaurant: restaurants[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantDetailsPage(
                            restaurant: restaurants[index],
                          ),
                        ),
                      );
                    },
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

class RecommendedDishesSection extends StatelessWidget {
  final List<RecommendedDishModel> dishes;
  final Function(RecommendedDishModel) onDishTap;

  const RecommendedDishesSection({
    Key? key,
    required this.dishes,
    required this.onDishTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;
    final activeDishes = dishes.where((d) => d.isActive).toList();
    if (activeDishes.isEmpty) return const SizedBox.shrink();
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
                    fontSize: 28,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dish.menuItem?.photoUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  dish.menuItem!.photoUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, size: 40),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant_menu, size: 40),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.menuItem?.nom ?? '',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dish.menuItem != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${dish.menuItem!.prix.toStringAsFixed(0)} DA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorApp.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  if (dish.restaurant != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      dish.restaurant!.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 10,
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
}

class PromotionsSection extends StatelessWidget {
  final List<PromotionModel> promotions;
  final Function(PromotionModel) onPromotionTap;

  const PromotionsSection({
    Key? key,
    required this.promotions,
    required this.onPromotionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;
    final activePromotions = promotions
        .where((p) =>
            p.isActive &&
            DateTime.now().isAfter(p.startDate) &&
            DateTime.now().isBefore(p.endDate))
        .toList();
    if (activePromotions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              localizations.promotions,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: activePromotions.length,
              itemBuilder: (context, index) {
                return _PromotionCard(
                  promotion: activePromotions[index],
                  onTap: () => onPromotionTap(activePromotions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback onTap;

  const _PromotionCard({
    Key? key,
    required this.promotion,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorApp.primary,
              ColorApp.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ColorApp.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (promotion.badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    promotion.badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (promotion.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      promotion.description!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (promotion.restaurant != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      promotion.restaurant!.name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllRestaurantsSection extends StatelessWidget {
  final List<RestaurantModel> restaurants;

  const AllRestaurantsSection({
    Key? key,
    required this.restaurants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              localizations.allRestaurants,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                return RestaurantListItem(
                    restaurant: restaurants[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantDetailsPage(
                            restaurant: restaurants[index],
                          ),
                        ),
                      );
                    });
              },
            ),
          ),
        ],
      ),
    );
  }
}
