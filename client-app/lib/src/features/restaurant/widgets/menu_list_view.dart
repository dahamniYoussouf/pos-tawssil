import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../models/menu_model.dart';
import 'menu_item_card.dart';

class MenuListView extends StatelessWidget {
  final List<MenuModel> items;
  final Set<String> favoriteFoods;
  final String? selectedItemId;
  final Map<String, int> cartQuantities;
  final Function(MenuModel) onItemTap;
  final Function(String) onFavoriteToggle;

  const MenuListView({
    Key? key,
    required this.items,
    required this.favoriteFoods,
    required this.selectedItemId,
    required this.cartQuantities,
    required this.onItemTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
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

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
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
          rating: 2.7,
        );
      },
    );
  }
}
