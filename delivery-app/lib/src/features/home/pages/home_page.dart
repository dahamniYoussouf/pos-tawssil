import 'package:delivery_app/src/features/home/widgets/custom_bottom_navigation_bar.dart';
import 'package:delivery_app/src/features/orders/pages/order_history_page.dart';
import 'package:delivery_app/src/features/orders/pages/order_page.dart';
import 'package:delivery_app/src/features/orders/pages/track_orders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:delivery_app/src/features/profile/pages/profile_page.dart';
import 'package:delivery_app/src/features/home/cubit/navigation_cubit.dart';
import 'package:delivery_app/src/features/home/cubit/navigation_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DriverCubit>().fetchDriverProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navigationState) {
        return BlocBuilder<DriverCubit, DriverState>(
          builder: (context, driverState) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: IndexedStack(
                index: navigationState.currentIndex,
                children: [
                  const TrackOrdersPage(),
                  const OrderPage(),
                  const OrderHistoryPage(),
                  const ProfilePage(),
                ],
              ),
              bottomNavigationBar: CustomBottomNavigationBar(
                currentIndex: navigationState.currentIndex,
                onTap: context.read<NavigationCubit>().changeTab,
              ),
            );
          },
        );
      },
    );
  }
}
