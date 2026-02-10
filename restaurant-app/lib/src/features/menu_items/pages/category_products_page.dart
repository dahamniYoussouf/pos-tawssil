import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/menu_items/pages/create_menu_item_page.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/product_list_card.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';

class CategoryProductsPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryProductsPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  CategoryModel _getCategory(RestaurantState restaurantState) {
    if (restaurantState is RestaurantLoaded) {
      final categories = restaurantState.restaurant.categories ?? [];
      final found =
          categories.where((c) => c.id == widget.category.id).toList();
      if (found.isNotEmpty) return found.first;
    }
    return widget.category;
  }

  List<MenuItemModel> _getFilteredItems(CategoryModel category) {
    final items = category.items;
    if (_searchQuery.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery) ||
              (item.description?.toLowerCase().contains(_searchQuery) ??
                  false) ||
              (item.ingredients?.toLowerCase().contains(_searchQuery) ?? false),
        )
        .toList();
  }

  void _refreshCategory() {
    context.read<RestaurantCubit>().fetchRestaurantDetails();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<RestaurantCubit, RestaurantState>(
      buildWhen: (prev, curr) =>
          curr is RestaurantLoaded || curr is RestaurantInitial,
      builder: (context, restaurantState) {
        final category = _getCategory(restaurantState);
        final filteredItems = _getFilteredItems(category);

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textDark),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: Text(
              localizations.products,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(localizations),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      localizations.listOfProducts,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToCreateMenuItem(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _buildProductList(localizations, filteredItems, category),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: localizations.searchForStoreOrProducts,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 22,
            color: AppColors.iconMedium,
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProductList(
    AppLocalizations localizations,
    List<MenuItemModel> items,
    CategoryModel category,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.restaurant_menu : Icons.search_off,
              size: 64,
              color: AppColors.greyLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? localizations.noMenuItems
                  : localizations.noOrdersFound,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ProductListCard(
          menuItem: items[index],
          category: category,
          onUpdated: _refreshCategory,
        );
      },
    );
  }

  void _navigateToCreateMenuItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (context) => locator<MenuItemCubit>(),
          child: CreateMenuItemPage(categories: [widget.category]),
        ),
      ),
    ).then((_) => _refreshCategory());
  }
}
