import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../models/menu_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuModel item;
  final bool isFavorite;
  final bool isSelected;
  final bool isInCart;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const MenuItemCard({
    Key? key,
    required this.item,
    required this.isFavorite,
    required this.isSelected,
    required this.isInCart,
    required this.quantity,
    required this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: isSelected || isInCart
                  ? Border.all(
                      color: ColorApp.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image with Add Button overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.restaurant,
                                  size: 30, color: Colors.grey[400]),
                            );
                          },
                        ),
                      ),
                    ),

                    // Add button overlay at bottom-right corner of image
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: item.disponible
                              ? ColorApp.primary
                              : ColorApp.greyLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: ColorApp.white, width: 2),
                        ),
                        child: Center(
                          child: isInCart
                              ? Text(
                                  '$quantity',
                                  style: TextStyle(
                                    color: ColorApp.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Icon(
                                  Icons.add,
                                  color: ColorApp.white,
                                  size: 14,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 12),

                // Food Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        item.nom,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: 4),

                      // Description
                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      SizedBox(height: 6),

                      // Price
                      Text(
                        item.priceFormatted,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ColorApp.black,
                        ),
                      ),

                      // Additional info
                      if (!item.disponible) ...[
                        SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.notAvailable,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (isInCart) ...[
                        SizedBox(height: 2),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorApp.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .quantityInCart(quantity),
                            style: const TextStyle(
                              fontSize: 9,
                              color: ColorApp.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 8),

                // Heart icon on the right
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Separator line
        Container(
          height: 1,
          color: Colors.grey[200],
          margin: EdgeInsets.only(left: 16),
        ),
      ],
    );
  }
}
