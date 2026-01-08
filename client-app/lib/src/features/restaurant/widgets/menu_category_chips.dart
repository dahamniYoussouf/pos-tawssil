import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_details_cubit.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/menu_model.dart';

class MenuCategoryChips extends StatelessWidget {
  final List<MenuItemCategory> categories;
  final String? selectedCategoryId;

  const MenuCategoryChips({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final filteredCategories = categories.where((category) {
      final categoryName = category.nom.toLowerCase().trim();
      return categoryName != 'promo' &&
          categoryName != 'promotion' &&
          categoryName != 'promotions';
    }).toList();
    if (filteredCategories.isEmpty && categories.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 8),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isAllSelected = selectedCategoryId == "all";
                        return _buildCategoryTab(
                          label: AppLocalizations.of(context)!.all,
                          isSelected: isAllSelected,
                          onTap: () => context
                              .read<RestaurantDetailsCubit>()
                              .selectCategory("all"),
                        );
                      }
                      final cat = filteredCategories[index - 1];
                      final selected = cat.id == selectedCategoryId;
                      return _buildCategoryTab(
                        label: cat.nom,
                        isSelected: selected,
                        onTap: () => context
                            .read<RestaurantDetailsCubit>()
                            .selectCategory(cat.id),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      color: ColorApp.greyBorder,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ColorApp.primary : ColorApp.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                height: 3,
                width: label.length * 10.0,
                decoration: BoxDecoration(
                  color: ColorApp.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}
