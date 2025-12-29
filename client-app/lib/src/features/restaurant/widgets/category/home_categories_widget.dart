import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';

class HomeCategoriesWidget extends StatelessWidget {
  final List<HomeCategoryModel> categories;
  final Function(HomeCategoryModel) onCategoryTap;

  const HomeCategoriesWidget({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              localizations.categories,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _HomeCategoryCard(
                  category: categories[index],
                  onTap: () => onCategoryTap(categories[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCategoryCard extends StatelessWidget {
  final HomeCategoryModel category;
  final VoidCallback onTap;

  const _HomeCategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("fouad : category: ${category.toJson()}");
    print("fouad : category.imageUrl: ${category.imageUrl}");
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (category.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  category.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error,
                    size: 40,
                    color: ColorApp.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.restaurant,
                size: 40,
                color: ColorApp.primary,
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorApp.textBlack,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
