import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cart_cubit.dart';
import '../states/cart_state.dart';

class CartIcon extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;
  final bool showBackground;

  const CartIcon({
    Key? key,
    this.onPressed,
    this.iconColor = Colors.black,
    this.iconSize = 20,
    this.showBackground = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        int totalItems = 0;
        bool isNotEmpty = false;

        if (state is CartUpdated) {
          totalItems = state.totalItems;
          isNotEmpty = !state.isEmpty;
        }

        Widget iconButton = Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.local_grocery_store_outlined, color: iconColor, size: iconSize),
              onPressed: isNotEmpty ? onPressed : null,
            ),
            if (totalItems > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$totalItems',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );

        if (showBackground) {
          return Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: iconButton,
          );
        }

        return iconButton;
      },
    );
  }
}
