import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:client_app/src/features/order/widgets/order_tracking_steps_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    // final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateStr = order.createdAt != null
        ? DateFormat('dd sp yyyy, HH:mm').format(order.createdAt!)
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${order.orderNumber}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ColorApp.textBlack,
                          ),
                        ),
                        if (order.restaurantAddress != null)
                          Text(
                            order.restaurantAddress!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ColorApp.greyIconColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context, order.status),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ColorApp.greyIconColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Progress Bar
              OrderTrackingStepsWidget(orderStatus: order.status),

              const SizedBox(height: 16),
              Text(
                'Details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Items list (snippet)
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.name} x${item.quantity}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorApp.textGrey,
                          ),
                        ),
                        Text(
                          '${item.price.toStringAsFixed(0)} DA',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorApp.textGrey,
                          ),
                        ),
                      ],
                    ),
                  )),

              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'See more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorApp.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

              const Divider(
                  height: 24, thickness: 1, color: ColorApp.greyBorder),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${order.totalPrice.toStringAsFixed(0)} DA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'See Details',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ColorApp.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color backgroundColor;
    Color textColor;
    String label = status;

    switch (status) {
      case OrderStatus.delivered:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        label = 'Livré';
        break;
      case OrderStatus.declined:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        label = 'Annulée';
        break;
      case OrderStatus.pending:
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.delivering:
        backgroundColor = ColorApp.primary;
        textColor = Colors.white;
        label = 'En cours';
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
