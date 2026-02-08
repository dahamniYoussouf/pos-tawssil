import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_state.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final String restaurantName =
        order.restaurantName ?? localizations.restaurant;
    final String? restaurantPhoneNumber =
        null; // Should come from API if available
    final String restaurantAddress = order.restaurantAddress ?? '--';
    final String deliveryAddress = order.deliveryAddress ?? '--';
    final double? restaurantDistance = null; // Calculated or from API
    final int? restaurantTime = order.deliveryTimeMinutes;
    final double? totalDistance = order.deliveryDistance;
    final int? totalTime = order.deliveryTimeMinutes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, localizations, deliveryPrice),
            const SizedBox(height: 12),
            _buildTimeline(
              context,
              localizations,
              restaurantName,
              restaurantAddress,
              deliveryAddress,
              restaurantDistance ?? 0.0,
              restaurantTime ?? 0,
              totalDistance ?? 0.0,
              totalTime ?? 0,
              restaurantPhoneNumber,
            ),
            const SizedBox(height: 16),
            _buildAcceptButton(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations,
      double deliveryPrice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 24), // Spacer for centering
        Expanded(
          child: Center(
            child: Text(
              _formatPrice(deliveryPrice),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: Icon(
            Icons.close,
            color: Colors.grey[400],
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    AppLocalizations localizations,
    String restaurantName,
    String restaurantAddress,
    String deliveryAddress,
    double restaurantDistance,
    int restaurantTime,
    double totalDistance,
    int totalTime,
    String? restaurantPhoneNumber,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildIconContainer(MediaRes.homeIcon),
            Container(
              width: 1.5,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            _buildIconContainer(MediaRes.boxIcon),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationInfo(
                title: restaurantName,
                subtitle: restaurantPhoneNumber,
                address: restaurantAddress,
                distance: restaurantDistance,
                time: restaurantTime,
              ),
              const SizedBox(height: 16),
              _buildLocationInfo(
                title: localizations.home,
                address: deliveryAddress,
                distance: totalDistance,
                time: totalTime,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconContainer(String iconPath) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFF4B5563),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required String title,
    String? subtitle,
    required String address,
    required double distance,
    required int time,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        Text(
          address,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              "$distance KM",
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            const Text("—", style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 12),
            Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              "$time min",
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcceptButton(
      BuildContext context, AppLocalizations localizations) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      bloc: locator<OrdersCubit>(),
      builder: (context, state) {
        bool isLoading =
            state is OrderActionLoading && state.orderId == order.id;
        bool isEnabled = !isLoading;

        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: isEnabled
                ? () => locator<OrdersCubit>().assignOrderToDriver(order.id)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    localizations.acceptDelivery,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
