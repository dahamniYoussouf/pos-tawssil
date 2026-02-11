import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class OngoingOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OngoingOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy, HH:mm', 'fr').format(date);
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} DA';
  }

  Color _getBadgeColor() {
    final type = order.orderType?.toLowerCase() ?? 'delivery';
    if (type == 'pos' || type == 'pickup' || type == 'pick-up') {
      return AppColors.primaryColor;
    }
    return const Color(0xFF3B82F6);
  }

  String _getBadgeLabel(AppLocalizations l10n) {
    final type = order.orderType?.toLowerCase() ?? 'delivery';
    if (type == 'pos' || type == 'pickup' || type == 'pick-up') {
      return 'pick-up';
    }
    return 'Livraison';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Order number + badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.orderTitle(order.orderNumber),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getBadgeLabel(l10n),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Row 2: Date
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLightGrey,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 12),

              // Row 3: Total + Details + ...
              Row(
                children: [
                  Text(
                    'Total',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLightGrey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatPrice(order.totalPrice),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.details,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.more_horiz,
                            color: AppColors.black, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
