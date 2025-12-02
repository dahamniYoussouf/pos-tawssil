import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:restaurant_app/src/features/orders/pages/orders_page.dart';
import 'package:restaurant_app/src/features/statistics/pages/statistics_page.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';

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

    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, restaurantState) {
        if (restaurantState is RestaurantLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (restaurantState is RestaurantError) {
          return Scaffold(
            body: Center(
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
            ),
          );
        }
        return _buildHomePage(context, localizations);
      },
    );
  }

  Widget _buildHomePage(BuildContext context, AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tawsil Restaurant',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart,
                  color: AppColors.primaryColor),
              title: const Text('Commandes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.bar_chart, color: AppColors.primaryColor),
              title: Text(localizations.statistics),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.restaurant, color: AppColors.primaryColor),
              title: Text(localizations.restaurantDetails),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => locator<CategoryCubit>(),
                      child: const RestaurantDetailsPage(),
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(localizations.logout),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthCubit>().logout();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          localizations.orders,
          style: TextStyle(color: AppColors.primaryColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: const OrdersPage(),
    );
  }
}
