import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_state.dart';
import 'package:flutter_svg/svg.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/l10n/app_localizations.dart';

class DailyDealCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const DailyDealCard({
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
            ? '${(restaurant.distance! / 1000).toStringAsFixed(1)} km'
            : '';
        final deliveryTimeText = '${restaurant.deliveryMax} min';

        return GestureDetector(
            onTap: onTap,
            child: Container(
              width: 190,
              margin: const EdgeInsets.only(right: 8, bottom: 8),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image section with overlays
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          restaurant.imageUrl,
                          height: 145,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // if (isExclusive)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorApp.promoColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'En exclusivite',
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
                            ),
                            // if (isFreeDelivery)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorApp.promoColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Livraison Gratuite',
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
                            ),
                          ],
                        ),
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
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            restaurant.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: ColorApp.textBlack,
                                  fontSize: 13,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                MediaRes.timeIcon,
                                width: 12,
                                height: 12,
                                color: ColorApp.textBlack,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: ColorApp.textBlack,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
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
                                          text: AppLocalizations.of(context)!
                                              .free,
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
                  ),
                ],
              ),
            ));
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 145,
      width: double.infinity,
      color: ColorApp.primary.withOpacity(0.1),
      child: const Icon(Icons.local_offer, size: 40, color: ColorApp.primary),
    );
  }
}
