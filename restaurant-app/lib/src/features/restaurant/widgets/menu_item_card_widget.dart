import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/menu_items/pages/create_menu_item_page.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';

class MenuItemCardWidget extends StatelessWidget {
  final MenuModel menuItem;
  final CategoryModel category;

  const MenuItemCardWidget({
    super.key,
    required this.menuItem,
    required this.category,
  });

  String _formatDescription(String description) {
    // Split by common separators and add bullet points
    final parts = description
        .split(RegExp(r'[,;]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return description;

    // If description already contains bullet points, return as is
    if (description.trim().startsWith('•')) {
      return description;
    }

    // Add bullet points to each part
    return parts.map((part) => '• $part').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => locator<MenuItemCubit>(),
                child: CreateMenuItemSheet(
                    categories: [category], menuItem: menuItem),
              ),
            ),
          ).then((_) {
            context.read<RestaurantCubit>().fetchRestaurantDetails();
          });
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: menuItem.photoUrl != null &&
                            menuItem.photoUrl!.isNotEmpty
                        ? Image.network(
                            menuItem.photoUrl!,
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: AppColors.greyLight,
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 48,
                                  color: AppColors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: 100,
                            color: AppColors.greyLight,
                            child: const Icon(
                              Icons.restaurant,
                              size: 48,
                              color: AppColors.grey,
                            ),
                          ),
                  )),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            menuItem.nom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (menuItem.description != null &&
                              menuItem.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                _formatDescription(menuItem.description!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${NumberFormat('#,###').format(menuItem.prix)} DA',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
