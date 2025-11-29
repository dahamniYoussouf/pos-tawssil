import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';

class NearbyOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onDismiss;

  const NearbyOrderCard({
    super.key,
    required this.order,
    this.onDismiss,
  });

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} DA';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final double deliveryPrice = order.deliveryPrice ?? 300.0;
    final String restaurantName = order.restaurantName ?? localizations.restaurant;
    final String restaurantPhoneNumber = "";
    final String? deliveryPersonPhoneNumber = order.client?.phoneNumber;
    final String restaurantAddress = order.restaurantAddress ?? '';
    final String deliveryAddress = order.deliveryAddress ?? '';
    final double restaurantDistance = order.deliveryDistance != null ? order.deliveryDistance! : 2.5;
    final int restaurantTime = (order.deliveryTimeMinutes != null ? order.deliveryTimeMinutes! / 3.0 : 12).round();
    final double totalDistance = order.deliveryDistance ?? 7.8;
    final int totalTime = order.estimatedDeliveryTime != null
        ? () {
            final minutes = (order.estimatedDeliveryTime!.difference(DateTime.now()).inMinutes).round();
            return minutes < 0 ? 0 : minutes;
          }()
        : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, localizations, deliveryPrice),
            const SizedBox(height: 16),
            Text(
              restaurantName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationSection(
              context,
              localizations,
              restaurantAddress,
              deliveryAddress,
              restaurantDistance,
              restaurantTime,
              totalDistance,
              totalTime,
              restaurantPhoneNumber,
              deliveryPersonPhoneNumber,
            ),
            const SizedBox(height: 16),
            _buildAcceptButton(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations, double deliveryPrice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${localizations.delivery} ${_formatPrice(deliveryPrice)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const Spacer(),
        if (onDismiss != null)
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close,
              color: AppColors.black,
              size: 24,
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection(
    BuildContext context,
    AppLocalizations localizations,
    String restaurantAddress,
    String deliveryAddress,
    double? restaurantDistance,
    int? restaurantTime,
    double? totalDistance,
    int? totalTime,
    String? restaurantPhoneNumber,
    String? deliveryPersonPhoneNumber,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddressRow(context, localizations, restaurantAddress, restaurantDistance, restaurantTime, true, restaurantPhoneNumber),
        const SizedBox(height: 12),
        _buildVerticalLine(),
        const SizedBox(height: 12),
        _buildAddressRow(context, localizations, deliveryAddress, totalDistance, totalTime, false, deliveryPersonPhoneNumber),
      ],
    );
  }

  Widget _buildAddressRow(BuildContext context, AppLocalizations localizations, String address, double? distance, int? time, bool isFirst, String? phoneNumber) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 16,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              if (phoneNumber != null && phoneNumber.isNotEmpty) const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (distance != null && time != null)
                Row(
                  children: [
                    Icon(Icons.location_searching_outlined, size: 16, color: AppColors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${distance.toStringAsFixed(2)} ${localizations.kilometers}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 16, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$time${localizations.minutesShort}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Container(
        width: 2,
        height: 20,
        color: AppColors.greyLight,
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, AppLocalizations localizations) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      bloc: locator<OrdersCubit>(),
      builder: (context, state) {
        // Check if we're loading for this specific order
        bool isLoading = state is OrderActionLoading && state.orderId == order.id;

        // Enable button when:
        // - Not loading for this order
        // - In OrdersLoaded state
        // - In OrderActionError state (to allow retry)
        // - In OrderActionSuccess state (though this shouldn't happen for this order if successful)
        bool isEnabled = !isLoading && (state is OrdersLoaded || state is OrderActionError || state is OrderActionSuccess || state is OrdersInitial || state is OrdersError);

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? () => locator<OrdersCubit>().assignOrderToDriver(order.id) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen.withValues(alpha: isEnabled ? 0.5 : 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              disabledBackgroundColor: AppColors.limeGreen.withValues(alpha: 0.3),
            ),
            child: isLoading
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                  )
                : Text(
                    localizations.accept,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isEnabled ? AppColors.black : AppColors.black.withValues(alpha: 0.5),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
