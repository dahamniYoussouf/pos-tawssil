import 'package:flutter/material.dart';
import '../../cart/widgets/cart_icon.dart';

class RestaurantDetailsHeader extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onBackPressed;
  final VoidCallback onCartPressed;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onSearchPressed;

  const RestaurantDetailsHeader({
    Key? key,
    required this.imageUrl,
    required this.onBackPressed,
    required this.onCartPressed,
    this.onFavoritePressed,
    this.onSearchPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: onBackPressed,
        ),
      ),
      actions: [
        CartIcon(
          onPressed: onCartPressed,
          iconColor: Colors.black,
          iconSize: 20,
          showBackground: true,
        ),
        if (onFavoritePressed != null)
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.favorite_outline, color: Colors.black, size: 20),
              onPressed: onFavoritePressed,
            ),
          ),
        if (onSearchPressed != null)
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.black, size: 20),
              onPressed: onSearchPressed,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
            );
          },
        ),
      ),
    );
  }
}

