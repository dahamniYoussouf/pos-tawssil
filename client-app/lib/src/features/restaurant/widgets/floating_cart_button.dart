import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:client_app/src/features/cart/states/cart_state.dart';

class FloatingCartButton extends StatelessWidget {
  final String restaurantId;
  final VoidCallback onTap;

  const FloatingCartButton({
    required this.restaurantId,
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final totalPrice =
            context.read<CartCubit>().getTotalPriceForRestaurant(restaurantId);

        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            height: 62,
            padding:
                const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: ColorApp.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.total} : ${totalPrice.toStringAsFixed(0)} DA',
                  style: const TextStyle(
                    color: ColorApp.textBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 43,
                      width: 200,
                      decoration: BoxDecoration(
                        color: ColorApp.primary,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.viewCart,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorApp.white,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
