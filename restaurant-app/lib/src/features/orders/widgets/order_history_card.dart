import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/formatters.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/core/res/media_res.dart';
import 'package:restaurant_app/src/features/orders/widgets/order_history_theme.dart';

class OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            formatHeaderDate(order.createdAt, context),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage(MediaRes.profilePic),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.client?.name ?? localizations.unknownClient,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              order.client?.address ??
                                  order.deliveryAddress ??
                                  '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: OrderHistoryStatusTheme.getStatusColor(
                              order.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (order.status.toLowerCase() == 'declined' ||
                                  order.status.toLowerCase() == 'cancelled')
                              ? localizations.cancelled
                              : (order.status.toLowerCase() == 'delivered' ||
                                      order.status.toLowerCase() == 'accepted')
                                  ? localizations.success
                                  : order.status,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${localizations.orders} #${order.orderNumber}     ${formatDisplayDateLocalized(order.createdAt, context)}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.grey),
                        ),
                      ),
                      if (order.orderType?.toLowerCase() == 'pos')
                        SvgPicture.asset(
                          MediaRes.posIcon,
                          width: 20,
                          height: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Total Price on the left
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localizations.totalPrice,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.black),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatPriceSpaced(order.totalPrice),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Details and More Icon on the right
                      InkWell(
                        onTap: onTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localizations.details,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const Icon(Icons.more_horiz,
                                color: AppColors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
