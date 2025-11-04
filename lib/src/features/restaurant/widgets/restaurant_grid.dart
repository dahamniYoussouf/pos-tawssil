import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import 'restaurant_card.dart';
import 'package:frontend/l10n/app_localizations.dart';

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
          Text(
            AppLocalizations.of(context)!.newToDiscover(restaurants.length),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          if (restaurants.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noRestaurantFound,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (onReload != null) ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: onReload,
                      child: Text(AppLocalizations.of(context)!.reload),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF006C4A),
                        foregroundColor: Colors.white,
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

