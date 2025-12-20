import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import 'package:client_app/l10n/app_localizations.dart';

class CategoryChipsList extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategoryTap;

  const CategoryChipsList({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.categories,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: 0.0,
                      color: ColorApp.textBlack,
                    ),
              ),
              Text(AppLocalizations.of(context)!.showAll,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ColorApp.primary,
                        fontSize: 18,
                      )),
            ],
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map((category) => _buildCategoryChip(category, context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CategoryModel category, BuildContext context) {
    return GestureDetector(
      onTap: () => onCategoryTap(category),
      child: Container(
        height: 84,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                category.iconPath,
                width: 45,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.restaurant, size: 55, color: Colors.grey);
                },
              ),
            ),
            SizedBox(width: 8),
            Text(
              category.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorApp.textBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
