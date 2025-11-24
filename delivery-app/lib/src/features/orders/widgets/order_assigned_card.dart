import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderAssignedCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onArrived;
  final VoidCallback onCancel;
  final bool isLoading;

  const OrderAssignedCard({
    super.key,
    required this.order,
    required this.onArrived,
    required this.onCancel,
    this.isLoading = false,
  });

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} DA';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final String restaurantName = order.restaurantName ?? localizations.restaurant;
    final String restaurantPhone = order.client?.phoneNumber ?? '';
    final String restaurantAddress = order.restaurantAddress ?? '';
    final String deliveryAddress = order.deliveryAddress ?? '';
    final int estimatedTime = order.deliveryTimeMinutes ?? 12;
    final double deliveryPrice = order.deliveryPrice ?? 300.0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, restaurantName),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.phone,
            restaurantPhone,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.access_time,
            '$estimatedTime${localizations.minutesShort}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.location_on,
            restaurantAddress.isNotEmpty ? restaurantAddress : deliveryAddress,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.description,
            '${localizations.orderNumberLabel}: #${order.orderNumber}',
          ),
          const SizedBox(height: 16),
          _buildExpandableRow(
            context,
            localizations,
            localizations.taskDetails,
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildExpandableRow(
            context,
            localizations,
            '${localizations.delivery}: ${_formatPrice(deliveryPrice)}',
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildExpandableRow(
            context,
            localizations,
            localizations.totalPrice,
            Icons.arrow_forward_ios,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildArrivedButton(context, localizations),
          const SizedBox(height: 12),
          _buildCancelButton(context, localizations),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String restaurantName) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              restaurantName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close,
              color: AppColors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableRow(
    BuildContext context,
    AppLocalizations localizations,
    String text,
    IconData trailingIcon, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            Icon(
              trailingIcon,
              size: 16,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivedButton(BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onArrived,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.limeGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                )
              : Text(
                  localizations.arrive,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onCancel,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.redColor, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            localizations.cancel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
