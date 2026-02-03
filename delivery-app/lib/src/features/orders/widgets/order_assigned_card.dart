import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/features/orders/cubit/assigned_order_cubit.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/pages/order_details_page.dart';
import 'package:delivery_app/src/features/orders/widgets/cancellation_reason_modal.dart';
import 'package:delivery_app/src/features/home/pages/home_page.dart';

class OrderAssignedCard extends StatelessWidget {
  final OrderModel order;

  const OrderAssignedCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssignedOrderCubit, AssignedOrderState>(
      builder: (context, state) {
        final currentOrder = state.order ?? order;
        final localizations = AppLocalizations.of(context)!;
        final isLoading = state.isActionLoading;
        final isDelivering = currentOrder.status == OrderStatus.delivering;

        final restaurantName =
            currentOrder.restaurantName ?? localizations.restaurant;
        final double deliveryDistance = currentOrder.deliveryDistance ?? 0.0;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDelivering)
                _buildClientHeader(currentOrder)
              else
                _buildRestaurantHeader(restaurantName),

              const SizedBox(height: 20),

              // Info Items
              _buildInfoItem(
                  Icons.location_on_outlined,
                  isDelivering
                      ? (currentOrder.deliveryAddress ?? 'Baraki, Sidi Moussa')
                      : (currentOrder.restaurantAddress ??
                          'No Address Provided')),

              Row(
                children: [
                  _buildInfoItemSvg(
                      MediaRes.distanceIcon, '$deliveryDistance KM',
                      expanded: false),
                  const SizedBox(width: 16),
                  Container(width: 20, height: 1, color: AppColors.greyLight),
                  const SizedBox(width: 16),
                  _buildInfoItem(Icons.access_time_outlined,
                      '${currentOrder.deliveryTimeMinutes ?? 12} min',
                      expanded: false),
                ],
              ),
              _buildInfoItem(Icons.description_outlined,
                  'Commande #${currentOrder.orderNumber}'),

              const SizedBox(height: 16),

              // Expandable Details
              _buildExpandableDetails(localizations, currentOrder),

              const SizedBox(height: 24),

              // Actions
              _buildActionButton(
                context,
                localizations,
                currentOrder.id,
                isLoading,
                isDelivering,
              ),
              const SizedBox(height: 12),
              if (!isDelivering)
                _buildCancelButton(
                  context,
                  localizations,
                  currentOrder.id,
                  isLoading,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantHeader(String restaurantName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: SvgPicture.asset(
            MediaRes.restaurantIcon,
            width: 28,
            height: 28,
            colorFilter:
                const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            restaurantName,
            style: AppTextStyles.gilmerBold.copyWith(
              fontSize: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientHeader(OrderModel order) {
    return Row(
      children: [
        // Client Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: SvgPicture.asset(
            MediaRes.clientIcon,
            width: 28,
            height: 28,
            colorFilter:
                const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),
        // Client Name and ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.client?.name ?? 'moncef azzouz',
                style: AppTextStyles.gilmerBold.copyWith(
                  fontSize: 24,
                ),
              ),
              Text(
                '#userid-${order.client?.email?.split('@').first ?? "12471241"}',
                style: AppTextStyles.gilmerMedium.copyWith(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        // Message and Call Buttons
        Row(
          children: [
            _buildActionIconSvg(MediaRes.chatIcon),
            const SizedBox(width: 12),
            _buildActionIcon(Icons.phone_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIconSvg(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SvgPicture.asset(
        assetPath,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Icon(icon, size: 24, color: AppColors.black),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {bool expanded = true}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.iconMedium),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.gilmerMedium.copyWith(
            fontSize: 15,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: expanded ? Row(children: [Expanded(child: content)]) : content,
    );
  }

  Widget _buildExpandableDetails(
      AppLocalizations localizations, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: SvgPicture.asset(
            MediaRes.walletFillIcon,
            width: 20,
            height: 20,
            colorFilter:
                const ColorFilter.mode(AppColors.textMedium, BlendMode.srcIn),
          ),
          title: const Text(
            "Détails De La Commande",
            style: AppTextStyles.gilmerBold,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.name} x${item.quantity}',
                              style: AppTextStyles.gilmerRegular.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(item.totalPrice)} DA',
                              style: AppTextStyles.gilmerBold.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.delivery,
                        style: AppTextStyles.gilmerRegular.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(order.deliveryPrice ?? 0)} DA',
                        style: AppTextStyles.gilmerBold.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.total,
                        style: AppTextStyles.gilmerBold.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(order.totalPrice)} DA',
                        style: AppTextStyles.gilmerBold.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItemSvg(String assetPath, String text,
      {bool expanded = true}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          assetPath,
          width: 20,
          height: 20,
          colorFilter:
              const ColorFilter.mode(AppColors.iconMedium, BlendMode.srcIn),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.gilmerMedium.copyWith(
            fontSize: 15,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: expanded ? Row(children: [Expanded(child: content)]) : content,
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    AppLocalizations localizations,
    String orderId,
    bool isLoading,
    bool isDelivering,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  if (isDelivering) {
                    context
                        .read<AssignedOrderCubit>()
                        .completeDelivery(orderId)
                        .whenComplete(() {
                      // delivered status go home pick new one
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HomePage(),
                          ),
                        );
                      }
                    });
                  } else {
                    final cubit = context.read<AssignedOrderCubit>();
                    cubit.markOrderArrived(orderId).whenComplete(() {
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsPage(
                              orderId: orderId,
                              cubit: cubit,
                            ),
                          ),
                        );
                      }
                    });
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                )
              : Text(
                  isDelivering ? localizations.delivered : localizations.arrive,
                  style: AppTextStyles.gilmerBold.copyWith(
                    fontSize: 18,
                    color: AppColors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(
    BuildContext context,
    AppLocalizations localizations,
    String orderId,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isLoading
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (childContext) => CancellationReasonModal(
                      onConfirm: (reason, otherReason) {
                        final finalReason =
                            otherReason != null && otherReason.isNotEmpty
                                ? '$reason: $otherReason'
                                : reason;
                        context.read<AssignedOrderCubit>().driverCancelOrder(
                              orderId,
                              reason: finalReason,
                            );
                      },
                    ),
                  );
                },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFF14336), width: 1),
            backgroundColor: const Color(0xFFFEF2F2), // Very light red
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            localizations.cancel,
            style: AppTextStyles.gilmerBold.copyWith(
              fontSize: 18,
              color: const Color(0xFFF14336),
            ),
          ),
        ),
      ),
    );
  }
}
