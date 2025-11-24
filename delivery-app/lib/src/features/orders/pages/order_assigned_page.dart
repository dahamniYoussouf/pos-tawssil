import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/cubit/assigned_order_cubit.dart';
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
                        context.read<AssignedOrderCubit>().fetchOrderById(orderId);
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
            return Stack(
              children: [
                OrderTrackingMap(
                  order: state.order,
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
    );
  }
}
