import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/home/cubit/navigation_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/assigned_order_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_state.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/pages/delivery_success_page.dart';
import 'package:delivery_app/src/features/orders/widgets/notification_card.dart';
import 'package:delivery_app/src/features/orders/widgets/order_assigned_card.dart';
import 'package:delivery_app/src/features/orders/widgets/order_tracking_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderAssignedPage extends StatelessWidget {
  final String orderId;

  const OrderAssignedPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocProvider<AssignedOrderCubit>(
      create: (context) => AssignedOrderCubit()..fetchOrderById(orderId),
      child: BlocListener<AssignedOrderCubit, AssignedOrderState>(
        listener: (context, state) {
          if (state.order?.status == OrderStatus.delivered) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DeliverySuccessPage(
                  tripEarnings: state.order?.deliveryPrice ?? 350.0,
                  distance: state.order?.deliveryDistance ?? 4.2,
                  orderCount: 1,
                  sessionTotal: 2400.0,
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: BlocBuilder<AssignedOrderCubit, AssignedOrderState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state.errorMessage != null && state.order == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.redColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<AssignedOrderCubit>()
                              .fetchOrderById(orderId);
                        },
                        child: Text(localizations.retry),
                      ),
                    ],
                  ),
                );
              }
              if (state.order == null) {
                return Center(
                  child: Text(localizations.orderNotFound),
                );
              }
              final isDelivering =
                  state.order!.status == OrderStatus.delivering;
              return Stack(
                children: [
                  OrderTrackingMap(
                    order: state.order,
                  ),
                  if (!isDelivering)
                    BlocBuilder<OrdersCubit, OrdersState>(
                      builder: (context, ordersState) {
                        List<OrderModel> nearbyOrders = [];
                        if (ordersState is OrdersLoaded) {
                          nearbyOrders = ordersState.orders;
                        } else if (ordersState is OrdersLoading) {
                          nearbyOrders = ordersState.orders;
                        }

                        if (nearbyOrders.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final latestOrder = nearbyOrders.first;

                        return Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: NotificationCard(
                              title: localizations.newOrderAvailable,
                              price:
                                  "+${latestOrder.deliveryPrice?.toInt() ?? 300} ${localizations.currency}",
                              distance:
                                  "${latestOrder.deliveryDistance ?? 0.0} ${localizations.kilometers}",
                              onActionTap: () {
                                // Switch to Radar tab and return home
                                context.read<NavigationCubit>().changeTab(0);
                                Navigator.of(context).popUntil((route) =>
                                    route.isFirst); // Should return to HomePage
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: OrderAssignedCard(
                      order: state.order!,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
