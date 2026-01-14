import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/l10n/app_localizations.dart';

class RecommendedDishCard extends StatelessWidget {
  final RecommendedDishModel dish;
  final VoidCallback onTap;

  const RecommendedDishCard({
    Key? key,
    required this.dish,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = dish.menuItem?.photoUrl;
    final dishName = dish.menuItem?.nom ?? '';
    final restaurant = dish.restaurant;
    final isFreeDelivery =
        restaurant?.deliveryFee == null || restaurant?.deliveryFee == 0;
    final distanceText = '0.8 km';
    final deliveryTimeText = '17 min';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
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
            Stack(
              alignment: Alignment.topLeft,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 145,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                if (restaurant != null)
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dishName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ColorApp.textBlack,
                            fontSize: 15,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (true) ...[
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 145,
      width: double.infinity,
      color: ColorApp.primary.withOpacity(0.1),
      child:
          const Icon(Icons.restaurant_menu, size: 40, color: ColorApp.primary),
    );
  }
}
