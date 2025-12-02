import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_cubit.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_state.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/categories/pages/create_category_page.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/categories_section_widget.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/menu_items_section_widget.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/search_bar_widget.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/pages/create_menu_item_page.dart';

class RestaurantDetailsPage extends StatefulWidget {
  const RestaurantDetailsPage({super.key});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<CategoryCubit, CategoryState>(
            listener: (context, state) {
              if (state is CategoryActionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is CategoryActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
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
              return RestaurantDetailsContent(
                searchController: _searchController,
                categories: restaurantState.restaurant.categories ?? [],
                menuItems: const [],
              );
            }
            return const SizedBox.shrink();
          },
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
              );
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
                    const SnackBar(
                      content: Text('Please create a category first'),
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
                      child: CreateMenuItemPage(categories: categories),
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

class RestaurantDetailsContent extends StatelessWidget {
  final TextEditingController searchController;
  final List<CategoryModel> categories;
  final List<MenuItem> menuItems;

  const RestaurantDetailsContent({
    super.key,
    required this.searchController,
    required this.categories,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          SearchBarWidget(controller: searchController),
          const SizedBox(height: 16),
          CategoriesSectionWidget(categories: categories),
          const SizedBox(height: 16),
          MenuItemsSectionWidget(menuItems: menuItems),
        ],
      ),
    );
  }
}
