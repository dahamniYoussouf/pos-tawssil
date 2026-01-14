import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../models/menu_model.dart';
import 'menu_item_card.dart';

class MenuListView extends StatelessWidget {
  final List<MenuModel>? items;
  final Map<String, List<MenuModel>>? groupedItems;
  final Set<String> favoriteFoods;
  final String? selectedItemId;
  final Map<String, int> cartQuantities;
  final Function(MenuModel) onItemTap;
  final Function(String) onFavoriteToggle;
  final bool showCategoryHeaders;

  const MenuListView({
    Key? key,
    this.items,
    this.groupedItems,
    required this.favoriteFoods,
    required this.selectedItemId,
    required this.cartQuantities,
    required this.onItemTap,
    required this.onFavoriteToggle,
    this.showCategoryHeaders = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showCategoryHeaders && groupedItems != null) {
      return _buildGroupedList(context);
    }
    if (items == null || items!.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildSimpleList(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMenuItemsAvailable,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items!.length,
      itemBuilder: (context, index) {
        final item = items![index];
        return _buildMenuItem(item);
      },
    );
  }

  Widget _buildGroupedList(BuildContext context) {
    if (groupedItems == null || groupedItems!.isEmpty) {
      return _buildEmptyState(context);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _calculateTotalItems(),
      itemBuilder: (context, index) {
        return _buildGroupedItem(index, context);
      },
    );
  }

  int _calculateTotalItems() {
    int count = 0;
    groupedItems!.forEach((category, items) {
      count += 1;
      count += items.length;
    });
    return count;
  }

  Widget _buildGroupedItem(int index, BuildContext context) {
    int currentIndex = 0;
    for (final entry in groupedItems!.entries) {
      if (currentIndex == index) {
        return _buildCategoryHeader(entry.key, context);
      }
      currentIndex++;
      final categoryItemsCount = entry.value.length;
      if (index < currentIndex + categoryItemsCount) {
        final itemIndex = index - currentIndex;
        return _buildMenuItem(entry.value[itemIndex]);
      }
      currentIndex += categoryItemsCount;
    }
    return const SizedBox.shrink();
  }

  Widget _buildCategoryHeader(String categoryName, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Text(
        categoryName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.2),
      ),
    );
  }

  Widget _buildMenuItem(MenuModel item) {
    final isFavorite = favoriteFoods.contains(item.id);
    final isSelected = selectedItemId == item.id;
    final quantity = cartQuantities[item.id] ?? 0;
    final isInCart = quantity > 0;

    return MenuItemCard(
      item: item,
      isFavorite: isFavorite,
      isSelected: isSelected,
      isInCart: isInCart,
      quantity: quantity,
      onTap: () => onItemTap(item),
      onFavoriteToggle: () => onFavoriteToggle(item.id),
      rating: item.rating,
    );
  }
}
