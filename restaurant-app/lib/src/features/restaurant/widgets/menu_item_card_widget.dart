import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class MenuItemCardWidget extends StatelessWidget {
  final MenuItem menuItem;

  const MenuItemCardWidget({
    super.key,
    required this.menuItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: menuItem.photoUrl != null && menuItem.photoUrl!.isNotEmpty
                  ? Image.network(
                      menuItem.photoUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
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
                      color: AppColors.greyLight,
                      child: const Icon(
                        Icons.restaurant,
                        size: 48,
                        color: AppColors.grey,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menuItem.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (menuItem.description != null &&
                    menuItem.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    menuItem.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${NumberFormat('#,###').format(menuItem.price)} DA',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

