import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../models/restaurant_model.dart';
import 'restaurant_info_card.dart';

class RestaurantInfoSection extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantInfoSection({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 2),
                  Text(
                    restaurant.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Poulet, Syrian Food',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RestaurantInfoCard(
                  label: AppLocalizations.of(context)!.deliveryFeeLabel,
                  value: '200 DA',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RestaurantInfoCard(
                  label: AppLocalizations.of(context)!.deliveryTimeLabel,
                  value: '${restaurant.deliveryMin}-${restaurant.deliveryMax} min',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

