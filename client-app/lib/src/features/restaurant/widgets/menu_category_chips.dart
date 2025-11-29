import 'package:flutter/material.dart';
import '../models/menu_model.dart';

class MenuCategoryChips extends StatelessWidget {
  final List<MenuItemCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const MenuCategoryChips({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return SizedBox.shrink();

    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final selected = cat.id == selectedCategoryId;
          return GestureDetector(
            onTap: () => onCategorySelected(cat.id),
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.black : Colors.grey[300]!,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  cat.nom,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

