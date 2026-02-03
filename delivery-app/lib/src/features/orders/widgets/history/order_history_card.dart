import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/widgets/history/dashed_vertical_divider.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final bool orderForHistory;
  final bool orderPage;
  const OrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
    this.orderForHistory = false,
    this.orderPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  MediaRes.orderIcon,
                  width: 37,
                  height: 37,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName ?? 'Restaurant',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${order.orderNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(context, order.status),
              ],
            ),
            Divider(
              color: AppColors.scaffoldBackground,
              thickness: 1,
              endIndent: 5,
              indent: 5,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16),
                DashedVerticalDivider(
                  color: AppColors.greyDark,
                  dashSpace: 3.5,
                  dashHeight: 10,
                ),
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.only(left: 32),
                        child: Column(
                          children: [
                            _buildLocationRow(
                              context,
                              l10n.from,
                              order.restaurantAddress ?? 'Restaurant Address',
                            ),
                            const SizedBox(height: 16),
                            _buildLocationRow(
                              context,
                              l10n.to,
                              order.deliveryAddress ?? 'Delivery Address',
                            ),
                          ],
                        ))),
              ],
            ),
            Divider(
              color: AppColors.scaffoldBackground,
              thickness: 1,
              endIndent: 5,
              indent: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      '${l10n.delivery} :',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.black,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${order.deliveryPrice?.toStringAsFixed(0) ?? '0'}DA',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                if (orderPage)
                  OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      backgroundColor: AppColors.primaryColor,
                      side: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.trackOrder,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (orderForHistory)
                  OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.viewDetails,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, String label, String address) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(
              MediaRes.locationIcon,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.black,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.black,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    Color backgroundColor;
    Color textColor;
    String label = status;

    switch (status) {
      case OrderStatus.delivered:
      case OrderStatus.collected:
        backgroundColor = AppColors.primaryColor1.withOpacity(0.2);
        textColor = AppColors.primaryColor1;
        label = l10n.statusDelivered;
        break;
      case OrderStatus.declined:
        backgroundColor = AppColors.redColor.withOpacity(0.2);
        textColor = AppColors.redColor;
        label = l10n.statusCancelled;
        break;
      case OrderStatus.pending:
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.assigned:
      case OrderStatus.arrived:
      case OrderStatus.delivering:
        backgroundColor = AppColors.blue.withOpacity(0.2);
        textColor = AppColors.blue;
        label = l10n.statusOngoing;
        break;
      default:
        backgroundColor = AppColors.greyVeryLight;
        textColor = AppColors.greyDark;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
