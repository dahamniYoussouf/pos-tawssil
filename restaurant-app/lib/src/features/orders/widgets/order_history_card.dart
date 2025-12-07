import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/features/orders/widgets/order_history_theme.dart';

class OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
  });

  String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) return '';
    final locale = Localizations.localeOf(context);
    return DateFormat('d MMM yyyy, hh:mm a', locale.languageCode).format(date);
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} DA';
  }

  String _getStatusLabel(String status, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'accepted':
        return localizations.accepted;
      case 'declined':
        return localizations.refuse;
      case 'delivered':
        return localizations.delivered;
      case 'preparing':
        return localizations.preparing;
      case 'delivering':
        return localizations.delivering;
      case 'assigned':
        return 'Assigné'; // TODO: Add to localizations
      case 'pending':
        return 'En attente'; // TODO: Add to localizations
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: OrderHistoryCardTheme.margin,
      elevation: OrderHistoryCardTheme.elevation,
      color: OrderHistoryTheme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OrderHistoryCardTheme.borderRadius),
        side: const BorderSide(
          color: OrderHistoryCardTheme.borderColor,
          width: OrderHistoryCardTheme.borderWidth,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OrderHistoryCardTheme.borderRadius),
        child: Padding(
          padding: OrderHistoryCardTheme.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, localizations),
              const SizedBox(height: 12),
              _buildCustomerInfo(context, localizations),
              const SizedBox(height: 12),
              _buildOrderDetails(context, localizations),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.orderTitle(order.orderNumber),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt, context),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.grey),
          onSelected: (value) {
            // Handle menu actions
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'details',
              child: Text(localizations.details),
            ),
            PopupMenuItem(
              value: 'contact',
              child: Text(localizations.contact),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final client = order.client;
    final clientName = client?.name ?? localizations.unknownClient;
    final clientAddress = client?.address ?? order.deliveryAddress ?? '';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.greyVeryLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greyLight, width: 1),
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              if (clientAddress.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  clientAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.orderNumberLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
            Text(
              '#${order.orderNumber}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.totalPrice,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            Text(
              _formatPrice(order.totalPrice),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: OrderHistoryStatusTheme.padding,
          decoration: BoxDecoration(
            color: OrderHistoryStatusTheme.getStatusColor(order.status),
            borderRadius: BorderRadius.circular(
              OrderHistoryStatusTheme.borderRadius,
            ),
          ),
          child: Text(
            _getStatusLabel(order.status, context),
            style: OrderHistoryStatusTheme.textStyle,
          ),
        ),
      ],
    );
  }
}
