import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriverStatusBottomSheet extends StatelessWidget {
  const DriverStatusBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, state) {
        final driver = state is DriverLoaded ? state.driver : null;
        final isActive = driver?.isActive ?? false;

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Status and Power Button Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFEFFFFB)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wb_sunny_outlined,
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive
                                  ? AppLocalizations.of(context)!
                                      .waitingForOrders
                                  : AppLocalizations.of(context)!.offline,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF064E3B)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Power Button
                      GestureDetector(
                        onTap: () async {
                          final driverCubit = context.read<DriverCubit>();
                          final ordersCubit = locator<OrdersCubit>();
                          final wasActive = driver?.isActive ?? false;

                          await driverCubit.toggleActiveStatus();

                          if (wasActive) {
                            // Going offline → clear orders immediately
                            ordersCubit.clearOrders();
                          } else {
                            // Going online → fetch fresh orders
                            ordersCubit.fetchOrdersNearby();
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.power_settings_new,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      // Revenue
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "0 ${AppLocalizations.of(context)!.currency}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.generatedRevenue,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),

                      // Orders
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "0",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.deliveredOrders,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
