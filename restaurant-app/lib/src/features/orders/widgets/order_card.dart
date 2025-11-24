import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_state.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({
    super.key,
    required this.order,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy, hh:mm a', 'fr').format(date);
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} DA';
  }

  Widget _buildItemIcon(String? imageUrl, String itemName) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(itemName),
        ),
      );
    }
    return _buildDefaultIcon(itemName);
  }

  Widget _buildDefaultIcon(String itemName) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.greyVeryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor, width: 1),
      ),
      child: Icon(
        Icons.fastfood,
        color: AppColors.primaryColor,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, localizations),
            const SizedBox(height: 32),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildDeliveryDetails(context, localizations),
            const SizedBox(height: 16),
            _buildTotalPrice(context, localizations),
            const SizedBox(height: 16),
            _buildActionButtons(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              localizations.orderNumberLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#${order.orderNumber}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: order.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _buildItemIcon(item.imageUrl, item.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '×${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatPrice(item.totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryDetails(BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.limeGreenLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDeliveryDetailRow(
            localizations.deliveryTime,
            order.estimatedDeliveryTime != null
                ? () {
                    final minutes = order.estimatedDeliveryTime!.difference(DateTime.now()).inMinutes;
                    return '${minutes < 0 ? 0 : minutes} ${localizations.minutes}';
                  }()
                : '10 ${localizations.minutes}',
          ),
          const SizedBox(height: 8),
          _buildDeliveryDetailRow(
            localizations.distance,
            order.deliveryDistance != null ? '${order.deliveryDistance!.toStringAsFixed(1)} ${localizations.kilometers}' : '0 ${localizations.kilometers}',
          ),
          const SizedBox(height: 8),
          _buildDeliveryDetailRow(
            localizations.deliveryPrice,
            order.deliveryPrice != null ? _formatPrice(order.deliveryPrice!) : '000 DA',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalPrice(BuildContext context, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localizations.totalPrice,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
        Text(
          _formatPrice(order.totalPrice),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations localizations) {
    // show buttons only if the order is pending
    return Visibility(
        visible: order.status == OrderStatus.pending,
        child: BlocBuilder<OrdersCubit, OrdersState>(builder: (context, state) {
          final actionLoading = state is OrderActionLoading && state.orderId == order.id;
          final isCancelLoading = actionLoading && state.actionType == OrderActionType.cancel;
          final isAcceptLoading = actionLoading && state.actionType == OrderActionType.accept;
          
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (isCancelLoading || isAcceptLoading) ? null : () => context.read<OrdersCubit>().cancelOrder(order.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isCancelLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                          ),
                        )
                      : Text(
                          localizations.refuse,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isCancelLoading || isAcceptLoading) ? null : () => context.read<OrdersCubit>().acceptOrder(order.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isAcceptLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          localizations.accept,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ],
          );
        }));
  }
}
