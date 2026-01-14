import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/menu_model.dart';
import '../../../core/widgets/menu_item_detail_page.dart';

class PromoSectionWidget extends StatelessWidget {
  final List<MenuModel> promoItems;
  final Map<String, int> cartQuantities;
  final Set<String> favoriteFoods;
  final Function(String) onFavoriteToggle;

  const PromoSectionWidget({
    Key? key,
    required this.promoItems,
    required this.cartQuantities,
    required this.favoriteFoods,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (promoItems.isEmpty) {
      return const SizedBox.shrink();
    }
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            localizations.promotions,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorApp.textBlack,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: promoItems.length,
            itemBuilder: (context, index) {
              final item = promoItems[index];
              return _PromoCard(
                item: item,
                quantity: cartQuantities[item.id] ?? 0,
                isFavorite: favoriteFoods.contains(item.id),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuItemDetailPage(menuItem: item),
                    ),
                  );
                },
                onFavoriteToggle: () => onFavoriteToggle(item.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final MenuModel item;
  final int quantity;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _PromoCard({
    Key? key,
    required this.item,
    required this.quantity,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isInCart = quantity > 0;
    final hasDiscount =
        item.displayPrice != null && item.displayPrice! < item.prix;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                  child: Image.network(
                    item.imageUrl,
                    width: 180,
                    height: 140,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 180,
                        height: 140,
                        color: ColorApp.backgroundGrey,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: ColorApp.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 180,
                        height: 140,
                        color: ColorApp.backgroundGrey,
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: ColorApp.greyLight,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.disponible
                          ? ColorApp.primary
                          : ColorApp.greyLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isInCart
                          ? Text(
                              '$quantity',
                              style: const TextStyle(
                                color: ColorApp.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : SvgPicture.asset(
                              MediaRes.addIcon,
                              colorFilter: const ColorFilter.mode(
                                ColorApp.white,
                                BlendMode.srcIn,
                              ),
                              width: 18,
                              height: 18,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 12, right: 12, top: 10, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorApp.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          '${item.prix.toStringAsFixed(0)} DA',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ColorApp.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        hasDiscount && item.displayPrice != null
                            ? '${item.displayPrice!.toStringAsFixed(0)} DA'
                            : item.priceFormatted,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorApp.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_border,
                        size: 14,
                        color: ColorApp.greyIconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.rating != null
                            ? '${item.rating!.toStringAsFixed(1)} (0)'
                            : '4.9 (893)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ColorApp.greyIconColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
