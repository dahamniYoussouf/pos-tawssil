import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_cubit.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_state.dart';
import 'package:restaurant_app/src/features/categories/pages/create_category_page.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/pages/create_menu_item_page.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/category_selection_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/categories_section_widget.dart';

class RestaurantDetailsPage extends StatefulWidget {
  const RestaurantDetailsPage({super.key});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Only fetch if not already loaded
    final currentState = context.read<RestaurantCubit>().state;
    if (currentState is! RestaurantLoaded) {
      context.read<RestaurantCubit>().fetchRestaurantDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          localizations.restaurantDetails,
          style: const TextStyle(color: AppColors.primaryColor),
        ),
      ),
      body: BlocProvider.value(
        value: locator<CategorySelectionCubit>(),
        child: MultiBlocListener(
          listeners: [
            BlocListener<CategoryCubit, CategoryState>(
              listener: (context, state) {
                if (state is CategoryError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is CategorySuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message ?? 'Success'),
                      backgroundColor: AppColors.primaryColor,
                    ),
                  );
                  context.read<RestaurantCubit>().fetchRestaurantDetails();
                }
              },
            ),
            BlocListener<RestaurantCubit, RestaurantState>(
              listener: (context, state) {
                if (state is RestaurantError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<RestaurantCubit, RestaurantState>(
            builder: (context, restaurantState) {
              if (restaurantState is RestaurantLoaded) {
                return CategoriesSectionWidget(
                  categories: restaurantState.restaurant.categories ?? [],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create_category_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCategoryPage(),
                ),
              ).then((_) {
                context.read<RestaurantCubit>().fetchRestaurantDetails();
              });
            },
            backgroundColor: AppColors.primaryColor,
            icon: const Icon(Icons.add, color: AppColors.white),
            label: Text(
              localizations.createCategory,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'create_menu_item_fab',
            onPressed: () {
              final restaurantState = context.read<RestaurantCubit>().state;
              if (restaurantState is RestaurantLoaded) {
                final categories = restaurantState.restaurant.categories ?? [];
                if (categories.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.createCategoryFirst),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => locator<MenuItemCubit>(),
                      child: CreateMenuItemSheet(categories: categories),
                    ),
                  ),
                ).then((_) {
                  context.read<RestaurantCubit>().fetchRestaurantDetails();
                });
              }
            },
            backgroundColor: AppColors.primaryColor,
            icon: const Icon(Icons.restaurant_menu, color: AppColors.white),
            label: Text(
              localizations.createMenuItem,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
