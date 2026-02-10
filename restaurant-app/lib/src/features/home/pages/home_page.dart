import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/home/cubit/navigation_cubit.dart';
import 'package:restaurant_app/src/features/home/cubit/navigation_state.dart';
import 'package:restaurant_app/src/features/home/widgets/custom_bottom_navigation_bar.dart';
import 'package:restaurant_app/src/features/orders/pages/history_page.dart';
import 'package:restaurant_app/src/features/profile/pages/profile_page.dart';
import 'package:restaurant_app/src/features/orders/pages/orders_page.dart';
import 'package:restaurant_app/src/features/menu_items/pages/menu_page.dart';
import 'package:restaurant_app/src/features/statistics/pages/statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<RestaurantCubit>().fetchRestaurantDetails();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navigationState) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: IndexedStack(
            index: navigationState.currentIndex,
            children: const [
              OrdersPage(),
              HistoryPage(),
              StatisticsPage(),
              MenuPage(),
              ProfilePage(),
            ],
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: navigationState.currentIndex,
            onTap: context.read<NavigationCubit>().changeTab,
          ),
        );
      },
    );
  }
}
