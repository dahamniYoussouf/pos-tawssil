import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/widgets/daily_deals/daily_deal_card.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DailyDealsWidget extends StatelessWidget {
  final List<DailyDealModel> dailyDeals;
  final List<RestaurantModel> restaurants;
  final Function(RestaurantModel) onDealTap;

  const DailyDealsWidget({
    Key? key,
    required this.dailyDeals,
    required this.restaurants,
    required this.onDealTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dailyDeals.isEmpty) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;

    // Look up restaurants by their IDs from dailyDeals
    final restaurantMap = {
      for (var restaurant in restaurants) restaurant.id: restaurant
    };
    final activeRestaurants = dailyDeals
        .map((deal) => restaurantMap[deal.restaurantId])
        .whereType<RestaurantModel>()
        .toList();

    if (activeRestaurants.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned(
            right: 0,
            top: 0,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(MediaRes.promoBackGroundImage))),
        Container(
            margin: EdgeInsets.only(top: 8, left: 8, right: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: ColorApp.greyDivider.withValues(alpha: 0.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    localizations.dailyDeals + ' 🎉',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: ColorApp.textBlack,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    localizations.dailyDealsSubtitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: ColorApp.grey,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: CarouselSlider.builder(
                    itemCount: activeRestaurants.length,
                    itemBuilder: (context, index, realIndex) {
                      return DailyDealCard(
                        restaurant: activeRestaurants[index],
                        onTap: () => onDealTap(activeRestaurants[index]),
                      );
                    },
                    options: CarouselOptions(
                      autoPlay: true,
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 500),
                      height: 230,
                      viewportFraction: 240 / MediaQuery.of(context).size.width,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.2,
                      enableInfiniteScroll: true,
                      padEnds: false,
                    ),
                  ),
                ),
              ],
            )),
      ],
    );
  }
}
