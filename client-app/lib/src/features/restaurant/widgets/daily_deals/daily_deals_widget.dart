import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/l10n/app_localizations.dart';

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
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              localizations.dailyDeals,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
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
        ],
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.all(4),
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
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  promotion.restaurant!.imageUrl!,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: ColorApp.primary.withOpacity(0.1),
                    child: const Icon(Icons.local_offer, size: 40),
                  ),
                ),
              ),
            ),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (promotion.badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ColorApp.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            promotion.badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (promotion.description != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            promotion.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                  // if (promotion.restaurant != null) ...[
                  //   const SizedBox(height: 8),
                  //   Text(
                  //     promotion.restaurant!.name,
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //           color: ColorApp.primary,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //   ),
                  // ],
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}
