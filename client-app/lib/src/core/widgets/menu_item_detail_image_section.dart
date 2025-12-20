import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';

class MenuItemDetailImageSection extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;

  const MenuItemDetailImageSection({
    Key? key,
    required this.imageUrl,
    required this.onBackPressed,
    required this.onFavoritePressed,
    required this.isFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          width: double.infinity,
          height: 300,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: ColorApp.grey,
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: ColorApp.grey,
                  ),
                );
              },
            ),
          ),
        ),
        _MenuDetailBackButton(onPressed: onBackPressed),
        _MenuDetailFavoriteButton(
          onPressed: onFavoritePressed,
          isFavorite: isFavorite,
        ),
      ],
    );
  }
}

class _MenuDetailBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MenuDetailBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 35,
      left: 16,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ColorApp.greyLight.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ColorApp.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.arrow_back,
            color: ColorApp.white,
            size: 20,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _MenuDetailFavoriteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isFavorite;

  const _MenuDetailFavoriteButton({
    required this.onPressed,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ColorApp.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: ColorApp.grey,
            width: 1,
          ),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? ColorApp.redColor : ColorApp.primary,
            size: 24,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

