import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/core/utils/global_function.dart';
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
    return BlocBuilder<HomepageCubit, HomepageState>(
      builder: (context, state) {
        // Check if delivery is free
        final isFreeDelivery =
            restaurant.deliveryFee == null || restaurant.deliveryFee == 0;

        // Format distance and delivery time
        final distanceText = restaurant.distance != null
            ? '${restaurant.distance!.toStringAsFixed(1)} km'
            : '';
        final deliveryTimeText = restaurant.deliveryMin > 0
            ? restaurant.deliveryMax > restaurant.deliveryMin
                ? '${restaurant.deliveryMin}-${restaurant.deliveryMax} min'
                : '${restaurant.deliveryMin} min'
            : '';

        // Format rating with count
        final ratingText = restaurant.ratersCount != null &&
                restaurant.ratersCount! > 0
            ? '${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratersCount})'
            : restaurant.rating.toStringAsFixed(1);

        // Check if restaurant is favorited
        final isFavorited = restaurant.favoriteUuid != null &&
            restaurant.favoriteUuid!.isNotEmpty;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 170,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section with overlays
                  Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 110,
                        color: Colors.grey.shade100,
                        child: Image.network(
                          restaurant.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.restaurant,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
                      ),

                      // Rating overlay (top-right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ratingText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Wrap(
                            spacing: 4,
                            children: List.generate(
                                restaurant.promotions.length,
                                (index) => restaurant
                                            .promotions[index].badgeText !=
                                        null
                                    ? Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasNumberInText(restaurant
                                                      .promotions[index]
                                                      .badgeText ??
                                                  '')
                                              ? ColorApp.promoYellowColor
                                              : ColorApp.promoGreenColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          restaurant.promotions[index]
                                                  .badgeText ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: ColorApp.textBlack,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : const SizedBox.shrink())),
                      ),
                    ],
                  ),
                  // Content section
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorApp.textBlack,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    MediaRes.timeIcon,
                                    width: 14,
                                    height: 14,
                                    colorFilter: ColorFilter.mode(
                                        ColorApp.textBlack, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ColorApp.textBlack,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          if (distanceText.isNotEmpty) ...[
                                            TextSpan(text: distanceText),
                                            const TextSpan(text: ' - '),
                                          ],
                                          if (deliveryTimeText.isNotEmpty)
                                            TextSpan(text: deliveryTimeText),
                                          if (isFreeDelivery) ...[
                                            const TextSpan(text: '  •  '),
                                            const TextSpan(
                                              text: 'Gratuite',
                                              style: TextStyle(
                                                color: ColorApp.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Favorite icon
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement favorite toggle
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFavorited
                                    ? ColorApp.primary
                                    : ColorApp.grey.withOpacity(0.3),
                                width: 1.5,
                              ),
                              color: isFavorited
                                  ? ColorApp.primary.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              isFavorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: isFavorited
                                  ? ColorApp.primary
                                  : ColorApp.textBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Delivery info row
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
