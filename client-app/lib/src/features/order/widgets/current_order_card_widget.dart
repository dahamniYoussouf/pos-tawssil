import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:client_app/src/features/order/cubit/order_cubit.dart';
import 'package:client_app/src/features/order/cubit/order_state.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:client_app/src/features/order/pages/order_tracking_page.dart';

class CurrentOrderCardWidget extends StatelessWidget {
  const CurrentOrderCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final orderCubit = locator<OrderCubit>();

    return BlocBuilder<OrderCubit, OrderState>(
      bloc: orderCubit,
      builder: (BuildContext context, OrderState state) {
        // Only show card if there's an active order
        if (state is! OrderLoaded &&
            state is! OrderCreated &&
            state is! OrderRefused &&
            state is! OrderDelayed) {
          return const SizedBox.shrink();
        }

        final OrderModel? order = _extractOrderFromState(state);

        // Don't show if order is completed
        if (order == null ||
            order.status == OrderStatus.delivered ||
            order.status == OrderStatus.collected) {
          return const SizedBox.shrink();
        }

        return _buildOrderCard(context, order, localization);
      },
    );
  }

  OrderModel? _extractOrderFromState(OrderState state) {
    if (state is OrderLoaded) {
      return state.order;
    }
    if (state is OrderCreated) {
      return state.order;
    }
    if (state is OrderRefused) {
      return state.order;
    }
    if (state is OrderDelayed) {
      return state.order;
    }
    return null;
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    AppLocalizations localization,
  ) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: ColorApp.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ColorApp.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      order.restaurantImageUrl ?? '',
                      width: 60,
                      height: 75,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: ColorApp.primary,
                          ),
                        );
                      },
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.restaurant,
                            size: 40, color: ColorApp.grey);
                      },
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        order.restaurantName ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColorApp.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        order.orderType == 'delivery'
                            ? localization.delivery
                            : localization.pickup,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColorApp.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                      padding: EdgeInsets.only(right: 12),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorApp.promoGreenColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _navigateToOrderTracking(context, order.id);
                          },
                          child: Text(localization.track,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: ColorApp.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  )))),
                ])));
  }

  void _navigateToOrderTracking(BuildContext context, String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingPage(orderId: orderId),
      ),
    );
  }
}
