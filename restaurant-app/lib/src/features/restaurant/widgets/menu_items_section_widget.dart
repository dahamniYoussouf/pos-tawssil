import 'package:flutter/material.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/menu_item_card_widget.dart';

class MenuItemsSectionWidget extends StatelessWidget {
  final CategoryModel category;
  final String searchQuery;

  const MenuItemsSectionWidget({
    super.key,
    required this.category,
    this.searchQuery = '',
  });

  List<MenuModel> _getFilteredItems() {
    if (searchQuery.isEmpty) {
      return category.items;
    }
    final query = searchQuery.toLowerCase().trim();
    return category.items
        .where((item) => item.nom.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final filteredItems = _getFilteredItems();

    if (category.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noMenuItems,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No menu items found',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return MenuItemCardWidget(
            menuItem: filteredItems[index], category: category);
      },
    );
  }
}
