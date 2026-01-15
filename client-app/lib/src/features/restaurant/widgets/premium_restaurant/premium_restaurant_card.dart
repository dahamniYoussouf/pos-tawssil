import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/utils/global_function.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_state.dart';
import 'package:flutter_svg/svg.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/l10n/app_localizations.dart';

class PremiumRestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;

  const PremiumRestaurantCard({
    Key? key,
    required this.restaurant,
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
            ? '${(restaurant.distance! / 1000).toStringAsFixed(1)} km'
            : '';
        final deliveryTimeText = '${restaurant.deliveryMax} min';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailsPage(
                  restaurant: restaurant,
                ),
              ),
            );
          },
          child: Container(
            width: 190,
            margin: const EdgeInsets.only(right: 16, bottom: 16, left: 2),
            decoration: BoxDecoration(
              color: ColorApp.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section with overlays
                Stack(
                  fit: StackFit.passthrough,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        restaurant.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      ),
                    ),
                    // Overlay badges (top-left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                          spacing: 4,
                          children: List.generate(
                              restaurant.promotions.length,
                              (index) => restaurant
                                          .promotions[index].badgeText !=
                                      null
                                  ? Container(
                                      margin: const EdgeInsets.only(bottom: 6),
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
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        restaurant
                                                .promotions[index].badgeText ??
                                            '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontFamily: 'Inter',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: ColorApp.textBlack,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : const SizedBox.shrink())),
                    ),
                    // Rating overlay (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: ColorApp.premiumColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ColorApp.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Content section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        restaurant.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: ColorApp.textBlack,
                                  fontSize: 16,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            MediaRes.timeIcon,
                            width: 14,
                            height: 14,
                            color: ColorApp.textBlack,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: ColorApp.textBlack,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                children: [
                                  if (distanceText.isNotEmpty) ...[
                                    TextSpan(text: distanceText),
                                    const TextSpan(text: ' - '),
                                  ],
                                  if (deliveryTimeText.isNotEmpty)
                                    TextSpan(text: deliveryTimeText),
                                  if (isFreeDelivery) ...[
                                    const TextSpan(text: ' • '),
                                    TextSpan(
                                      text: AppLocalizations.of(context)!.free,
                                      style: TextStyle(
                                        color: ColorApp.primary,
                                        fontSize: 13,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: ColorApp.primary.withOpacity(0.1),
      child: const Icon(Icons.local_offer, size: 40, color: ColorApp.primary),
    );
  }
}
