import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/menu_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuModel item;
  final bool isFavorite;
  final bool isSelected;
  final bool isInCart;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final double? rating;
  final int? ratingCount;

  const MenuItemCard({
    Key? key,
    required this.item,
    required this.isFavorite,
    required this.isSelected,
    required this.isInCart,
    required this.quantity,
    required this.onTap,
    required this.onFavoriteToggle,
    this.rating,
    this.ratingCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MenuItemDetails(
                item: item,
                rating: rating,
                ratingCount: ratingCount,
                isInCart: isInCart,
                quantity: quantity,
              ),
            ),
            const SizedBox(width: 16),
            MenuItemImage(
              imageUrl: item.imageUrl,
              isAvailable: item.disponible,
              isInCart: isInCart,
              quantity: quantity,
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItemDetails extends StatelessWidget {
  final MenuModel item;
  final double? rating;
  final int? ratingCount;
  final bool isInCart;
  final int quantity;

  const MenuItemDetails({
    Key? key,
    required this.item,
    this.rating,
    this.ratingCount,
    required this.isInCart,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.nom,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorApp.textBlack,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.prix.toStringAsFixed(0)} DA',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ColorApp.primary,
          ),
        ),
        if (item.description != null && item.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.description!,
            style: const TextStyle(
              fontSize: 14,
              color: ColorApp.textBlack,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        ],
        if (rating != null) ...[
          const SizedBox(height: 4),
          MenuItemRating(
            rating: rating!,
            ratingCount: ratingCount,
          ),
        ],
      ],
    );
  }
}

class MenuItemRating extends StatelessWidget {
  final double rating;
  final int? ratingCount;

  const MenuItemRating({
    Key? key,
    required this.rating,
    this.ratingCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.star_border,
          size: 16,
          color: ColorApp.greyIconColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)}${ratingCount != null ? ' ($ratingCount)' : ''}',
          style: const TextStyle(
            fontSize: 14,
            color: ColorApp.greyIconColor,
          ),
        ),
      ],
    );
  }
}

class MenuItemImage extends StatelessWidget {
  final String imageUrl;
  final bool isAvailable;
  final bool isInCart;
  final int quantity;

  const MenuItemImage({
    Key? key,
    required this.imageUrl,
    required this.isAvailable,
    required this.isInCart,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: ColorApp.primary,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
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
            bottom: 0,
            right: 0,
            child: AddButton(
              isAvailable: isAvailable,
              isInCart: isInCart,
              quantity: quantity,
            ),
          ),
        ],
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  final bool isAvailable;
  final bool isInCart;
  final int quantity;

  const AddButton({
    Key? key,
    required this.isAvailable,
    required this.isInCart,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isAvailable ? ColorApp.primary : ColorApp.greyLight,
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
                colorFilter: ColorFilter.mode(ColorApp.white, BlendMode.srcIn),
                width: 18,
                height: 18,
              ),
      ),
    );
  }
}
