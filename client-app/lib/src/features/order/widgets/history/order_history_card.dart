import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:client_app/src/features/order/widgets/order_tracking_steps_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../../cubit/order_history_cubit.dart';
import '../../cubit/order_history_state.dart';

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateStr = order.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt!)
        : '';

    final isOngoing = order.status != OrderStatus.delivered &&
        order.status != OrderStatus.collected &&
        order.status != OrderStatus.declined;

    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      buildWhen: (previous, current) {
        if (previous is OrderHistoryLoaded && current is OrderHistoryLoaded) {
          return previous.expandedOrderIds.contains(order.id) !=
              current.expandedOrderIds.contains(order.id);
        }
        return true;
      },
      builder: (context, state) {
        final isExpanded = state is OrderHistoryLoaded &&
            state.expandedOrderIds.contains(order.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: ColorApp.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ColorApp.greyBorder, width: 1),
          ),
          child: InkWell(
            onTap: () {
              context.read<OrderHistoryCubit>().toggleOrderExpansion(order.id);
            },
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
                              '#${order.orderNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ColorApp.textBlack,
                                fontSize: 20,
                              ),
                            ),
                            if (order.restaurantAddress != null ||
                                order.restaurantName != null)
                              Text(
                                order.restaurantName ??
                                    order.restaurantAddress!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ColorApp.greyIconColor,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildStatusBadge(context, order.status),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ColorApp.greyIconColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  if (isOngoing || isExpanded)
                    OrderTrackingStepsWidget(orderStatus: order.status),

                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: ColorApp.greyIconColor,
                    ),
                  ),

                  if (isExpanded) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.details,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items list
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                                l10n.totalValue(item.price.toStringAsFixed(0)),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ColorApp.textGrey,
                                ),
                              ),
                            ],
                          ),
                        )),

                    const Divider(
                        height: 24, thickness: 1, color: ColorApp.greyBorder),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.total,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          l10n.totalValue(order.totalPrice.toStringAsFixed(0)),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Suivre la commande Button
                    if (isOngoing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF111827), // Dark button
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.trackOrder,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    Color backgroundColor;
    Color textColor;
    String label = status;

    switch (status) {
      case OrderStatus.delivered:
        backgroundColor = const Color(0xFFE0E7FF); // Indigo light
        textColor = const Color(0xFF4338CA); // Indigo dark
        label = l10n.statusDelivered;
        break;
      case OrderStatus.declined:
        backgroundColor = const Color(0xFFFEE2E2); // Red light
        textColor = const Color(0xFFB91C1C); // Red dark
        label = l10n.statusCancelled;
        break;
      case OrderStatus.pending:
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.delivering:
        backgroundColor = const Color(0xFFD1FAE5); // Green light
        textColor = const Color(0xFF065F46); // Green dark
        label = l10n.statusOngoing;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
