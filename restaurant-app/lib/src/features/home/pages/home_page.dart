import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/home/cubit/navigation_cubit.dart';
import 'package:restaurant_app/src/features/home/cubit/navigation_state.dart';
import 'package:restaurant_app/src/features/home/widgets/custom_bottom_navigation_bar.dart';
import 'package:restaurant_app/src/features/menu/pages/menu_page.dart';
import 'package:restaurant_app/src/features/orders/pages/history_page.dart';
import 'package:restaurant_app/src/features/profile/pages/profile_page.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/orders/pages/orders_page.dart';
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
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navigationState) {
        return BlocBuilder<RestaurantCubit, RestaurantState>(
          builder: (context, restaurantState) {
            String title;
            if (restaurantState is RestaurantError) {
              title = localizations.error;
            } else {
              switch (navigationState.currentIndex) {
                case 0:
                  title = localizations.orders;
                  break;
                case 1:
                  title = localizations.orderHistory;
                  break;
                case 2:
                  title = localizations.statistics;
                  break;
                case 3:
                  title = "Menu";
                  break;
                case 4:
                  title = localizations.settings;
                  break;
                default:
                  title = localizations.appTitle;
              }
            }

            return Scaffold(
              backgroundColor: AppColors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0, bottom: 10),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildBody(
                          restaurantState, navigationState, localizations),
                    ),
                  ],
                ),
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

  Widget _buildBody(RestaurantState restaurantState,
      NavigationState navigationState, AppLocalizations localizations) {
    if (restaurantState is RestaurantLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (restaurantState is RestaurantError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              restaurantState.message,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<RestaurantCubit>().fetchRestaurantDetails();
              },
              child: Text(localizations.retry),
            ),
          ],
        ),
      );
    }
    return IndexedStack(
      index: navigationState.currentIndex,
      children: const [
        OrdersPage(),
        HistoryPage(),
        StatisticsPage(),
        MenuPage(),
        ProfilePage(),
      ],
    );
  }
}
