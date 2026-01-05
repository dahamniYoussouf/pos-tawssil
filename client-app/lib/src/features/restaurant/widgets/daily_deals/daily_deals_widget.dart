import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/homepage_cubit.dart';
import '../../cubit/homepage_state.dart';

class DailyDealsWidget extends StatelessWidget {
  final List<DailyDealModel> dailyDeals;
  final Function(DailyDealModel) onDealTap;

  const DailyDealsWidget({
    Key? key,
    required this.dailyDeals,
    required this.onDealTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dailyDeals.isEmpty) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;
    final activeDeals = dailyDeals
        .where((deal) =>
            deal.isActive &&
            DateTime.now().isAfter(deal.startDate) &&
            DateTime.now().isBefore(deal.endDate))
        .toList();
    if (activeDeals.isEmpty) return const SizedBox.shrink();
    return Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ColorApp.primary.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                localizations.dailyDeals,
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: activeDeals.length,
                itemBuilder: (context, index) {
                  return _DailyDealCard(
                    deal: activeDeals[index],
                    onTap: () => onDealTap(activeDeals[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ));
  }
}

class _DailyDealCard extends StatelessWidget {
  final DailyDealModel deal;
  final VoidCallback onTap;

  const _DailyDealCard({
    Key? key,
    required this.deal,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final promotion = deal.promotion;
    final imageUrl =
        promotion.menuItem?.photoUrl ?? promotion.restaurant?.imageUrl;

    return BlocBuilder<HomepageCubit, HomepageState>(
      builder: (context, state) {
        // Get promotions for this restaurant from the homepage state
        List<String> promotionBadges = [];
        if (state is HomepageLoaded && promotion.restaurantId != null) {
          promotionBadges = state.homepageData.promotions
              .where((promo) =>
                  promo.restaurantId == promotion.restaurantId &&
                  promo.isActive &&
                  promo.badgeText != null &&
                  promo.badgeText!.isNotEmpty)
              .map((promo) => promo.badgeText!)
              .toList();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 190,
            margin: const EdgeInsets.only(right: 16, bottom: 16),
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
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        imageUrl != null
                            ? Image.network(
                                imageUrl,
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                              )
                            : _buildPlaceholderImage(),
                        if (promotionBadges.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: promotionBadges
                                  .map((badgeText) => Container(
                                        width: 100,
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(.8),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ColorApp.textBlack,
                                  fontSize: 16,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ColorApp.grey,
                                      fontSize: 12,
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
      height: 130,
      width: double.infinity,
      color: ColorApp.primary.withOpacity(0.1),
      child: const Icon(Icons.local_offer, size: 40, color: ColorApp.primary),
    );
  }
}
