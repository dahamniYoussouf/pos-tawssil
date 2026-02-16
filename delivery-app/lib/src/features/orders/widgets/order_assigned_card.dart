import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
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

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              margin: isDelivering
                  ? const EdgeInsets.fromLTRB(16, 0, 16, 50)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: isDelivering
                    ? BorderRadius.circular(32)
                    : const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                          ? (currentOrder.deliveryAddress ?? '--')
                          : (currentOrder.restaurantAddress ?? '--')),

                  Row(
                    children: [
                      _buildInfoItemSvg(
                          MediaRes.distanceIcon, '$deliveryDistance KM',
                          expanded: false),
                      const SizedBox(width: 16),
                      Container(
                          width: 20, height: 1, color: AppColors.greyLight),
                      const SizedBox(width: 16),
                      _buildInfoItem(Icons.access_time_outlined,
                          '${currentOrder.deliveryTimeMinutes ?? "--"} min',
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
                    currentOrder,
                    isLoading,
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
            ),
            Positioned(
              top: -70,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  if (isDelivering) {
                    if (currentOrder.deliveryLatitude != null &&
                        currentOrder.deliveryLongitude != null) {
                      _openInGoogleMaps(currentOrder.deliveryLatitude!,
                          currentOrder.deliveryLongitude!);
                    }
                  } else {
                    if (currentOrder.restaurantLatitude != null &&
                        currentOrder.restaurantLongitude != null) {
                      _openInGoogleMaps(currentOrder.restaurantLatitude!,
                          currentOrder.restaurantLongitude!);
                    }
                  }
                },
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    MediaRes.locationShortcutIcon,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
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

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('google.navigation:q=$lat,$lng');
    final fallbackUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri);
    } else if (await launcher.canLaunchUrl(fallbackUri)) {
      await launcher.launchUrl(fallbackUri,
          mode: launcher.LaunchMode.externalApplication);
    }
  }

  Widget _buildClientHeader(OrderModel order) {
    return Row(
      children: [
        // Client Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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
                order.client?.name ?? 'Client',
                style: AppTextStyles.gilmerBold.copyWith(
                  fontSize: 24,
                ),
              ),
              Text(
                '#userid-${(order.client?.email?.split('@').first) ?? (order.client?.email != null ? order.client!.email! : (order.client?.id?.substring(0, 8) ?? "unknown"))}',
                style: AppTextStyles.gilmerMedium.copyWith(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        //  Call Buttons
        Row(
          children: [
            _buildActionIcon(
              Icons.phone_outlined,
              onTap: () async {
                final phone = order.client?.phoneNumber;
                if (phone != null) {
                  final uri = Uri.parse('tel:$phone');
                  if (await launcher.canLaunchUrl(uri)) {
                    await launcher.launchUrl(uri);
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(icon, size: 24, color: AppColors.black),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {bool expanded = true}) {
    final textWidget = Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.gilmerMedium.copyWith(
        fontSize: 15,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.iconMedium),
          const SizedBox(width: 12),
          if (expanded) Expanded(child: textWidget) else textWidget,
        ],
      ),
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
          title: Text(
            localizations.orderDetailsHeader,
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
    final textWidget = Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.gilmerMedium.copyWith(
        fontSize: 15,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            assetPath,
            width: 20,
            height: 20,
            colorFilter:
                const ColorFilter.mode(AppColors.iconMedium, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          if (expanded) Expanded(child: textWidget) else textWidget,
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    AppLocalizations localizations,
    OrderModel order,
    bool isLoading,
  ) {
    final bool isDelivering = order.status == OrderStatus.delivering;
    final bool isArrived = order.status == OrderStatus.arrived;

    String buttonLabel = localizations.arrive;
    if (isArrived) {
      buttonLabel = localizations.startDelivery;
    } else if (isDelivering) {
      buttonLabel = localizations.delivered;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                final cubit = context.read<AssignedOrderCubit>();
                if (isDelivering) {
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                MediaRes.successIcon,
                                width: 32,
                                height: 32,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.primaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              localizations.confirmDelivery,
                              style: AppTextStyles.gilmerBold.copyWith(
                                fontSize: 22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localizations.confirmDeliveryMessage,
                              style: AppTextStyles.gilmerMedium.copyWith(
                                fontSize: 16,
                                color: AppColors.textMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                    child: Text(
                                      localizations.no,
                                      style: AppTextStyles.gilmerBold.copyWith(
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      localizations.yes,
                                      style: AppTextStyles.gilmerBold.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (confirmed == true) {
                    await cubit.completeDelivery(order.id);
                  }
                } else if (isArrived) {
                  // If arrived at restaurant but haven't started delivery yet
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsPage(
                        orderId: order.id,
                        cubit: cubit,
                      ),
                    ),
                  );
                } else {
                  // Pending/Accepted -> Mark as Arrived
                  await cubit.markOrderArrived(order.id);
                  if (context.mounted && cubit.state.errorMessage == null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(
                          orderId: order.id,
                          cubit: cubit,
                        ),
                      ),
                    );
                  }
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
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                buttonLabel,
                style: AppTextStyles.gilmerBold.copyWith(
                  fontSize: 18,
                  color: AppColors.white,
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
    return SizedBox(
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
                      context
                          .read<AssignedOrderCubit>()
                          .driverCancelOrder(
                            orderId,
                            reason: finalReason,
                          )
                          .then((_) {
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false,
                          );
                        }
                      });
                    },
                  ),
                );
              },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFF14336), width: 1),
          backgroundColor: Colors.white,
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
    );
  }
}
