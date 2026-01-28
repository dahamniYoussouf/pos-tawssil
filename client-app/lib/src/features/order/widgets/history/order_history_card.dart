import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:client_app/src/features/order/widgets/order_tracking_steps_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  State<OrderHistoryCard> createState() => _OrderHistoryCardState();
}

class _OrderHistoryCardState extends State<OrderHistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateStr = widget.order.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(widget.order.createdAt!)
        : '';

    final isOngoing = widget.order.status != OrderStatus.delivered &&
        widget.order.status != OrderStatus.collected &&
        widget.order.status != OrderStatus.declined;

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
          setState(() {
            _isExpanded = !_isExpanded;
          });
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
                          '#${widget.order.orderNumber}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ColorApp.textBlack,
                            fontSize: 20,
                          ),
                        ),
                        if (widget.order.restaurantAddress != null ||
                            widget.order.restaurantName != null)
                          Text(
                            widget.order.restaurantName ??
                                widget.order.restaurantAddress!,
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
                      _buildStatusBadge(context, widget.order.status),
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

              // Progress Bar (Always show if it's ongoing, or based on mockup)
              if (isOngoing || _isExpanded)
                OrderTrackingStepsWidget(orderStatus: widget.order.status),

              Align(
                alignment: Alignment.center,
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: ColorApp.greyIconColor,
                ),
              ),

              if (_isExpanded) ...[
                const SizedBox(height: 16),
                Text(
                  'Détails',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                // Items list
                ...widget.order.items.map((item) => Padding(
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
                            '${item.price.toStringAsFixed(0)} DA',
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
                      'Total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${widget.order.totalPrice.toStringAsFixed(0)} DA',
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
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827), // Dark button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Suivre la commande',
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
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color backgroundColor;
    Color textColor;
    String label = status;

    switch (status) {
      case OrderStatus.delivered:
        backgroundColor = const Color(0xFFE0E7FF); // Indigo light
        textColor = const Color(0xFF4338CA); // Indigo dark
        label = 'LIVRÉ';
        break;
      case OrderStatus.declined:
        backgroundColor = const Color(0xFFFEE2E2); // Red light
        textColor = const Color(0xFFB91C1C); // Red dark
        label = 'ANNULÉE';
        break;
      case OrderStatus.pending:
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.delivering:
        backgroundColor = const Color(0xFFD1FAE5); // Green light
        textColor = const Color(0xFF065F46); // Green dark
        label = 'EN COURS';
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
