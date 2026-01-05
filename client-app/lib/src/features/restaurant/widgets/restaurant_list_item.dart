import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../models/restaurant_model.dart';
import '../cubit/homepage_cubit.dart';
import '../cubit/homepage_state.dart';

class RestaurantListItem extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const RestaurantListItem({
    Key? key,
    required this.restaurant,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<HomepageCubit, HomepageState>(
      builder: (context, state) {
        // Get promotions for this restaurant from the homepage state
        List<String> promotionBadges = [];
        if (state is HomepageLoaded) {
          promotionBadges = state.homepageData.promotions
              .where((promotion) =>
                  promotion.restaurantId == restaurant.id &&
                  promotion.isActive &&
                  promotion.badgeText != null &&
                  promotion.badgeText!.isNotEmpty)
              .map((promotion) => promotion.badgeText!)
              .toList();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ColorApp.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            restaurant.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        ),
                        // todo : remove move it  promotion badges
                        // if (promotionBadges.isNotEmpty)
                        //   Positioned(
                        //     top: 8,
                        //     left: 8,
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       mainAxisSize: MainAxisSize.min,
                        //       children: promotionBadges
                        //           .map((badgeText) => Container(
                        //                 width: 100,
                        //                 margin:
                        //                     const EdgeInsets.only(bottom: 4),
                        //                 padding: const EdgeInsets.symmetric(
                        //                   horizontal: 10,
                        //                   vertical: 6,
                        //                 ),
                        //                 decoration: BoxDecoration(
                        //                   color: Colors.red.withOpacity(.5),
                        //                   borderRadius:
                        //                       BorderRadius.circular(8),
                        //                 ),
                        //                 child: Text(
                        //                   badgeText,
                        //                   style: const TextStyle(
                        //                     fontSize: 10,
                        //                     fontWeight: FontWeight.bold,
                        //                     color: Colors.white,
                        //                   ),
                        //                   maxLines: 1,
                        //                   overflow: TextOverflow.ellipsis,
                        //                 ),
                        //               ))
                        //           .toList(),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      restaurant.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        restaurant.rating.toStringAsFixed(1),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                      ),
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${localizations.deliveryFeeLabel}: ${restaurant.deliveryFee != null ? '${restaurant.deliveryFee!.toStringAsFixed(0)} DA' : 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: ColorApp.grey,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                  child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ColorApp.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Exclusive Offer",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: ColorApp.textBlack,
                                        fontSize: 10,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ColorApp.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Free Delivery",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: ColorApp.textBlack,
                                        fontSize: 10,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ))
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
