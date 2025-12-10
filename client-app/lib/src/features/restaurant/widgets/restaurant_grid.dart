import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import 'restaurant_card.dart';
import 'package:client_app/l10n/app_localizations.dart';

class RestaurantGrid extends StatelessWidget {
  final List<RestaurantModel> restaurants;
  final Function(RestaurantModel) onRestaurantTap;
  final VoidCallback? onReload;

  const RestaurantGrid({
    Key? key,
    required this.restaurants,
    required this.onRestaurantTap,
    this.onReload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recommendations,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ColorApp.black,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.showAll,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: ColorApp.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (restaurants.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant, size: 48, color: ColorApp.grey),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noRestaurantFound,
                    style: const TextStyle(color: ColorApp.grey),
                  ),
                  if (onReload != null) ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: onReload,
                      child: Text(AppLocalizations.of(context)!.reload),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorApp.primary,
                        foregroundColor: ColorApp.white,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                return RestaurantCard(
                  restaurant: restaurants[index],
                  onTap: () => onRestaurantTap(restaurants[index]),
                );
              },
            ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
