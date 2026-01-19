import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MenuItemDetailBottomBar extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrementQuantity;
  final VoidCallback onIncrementQuantity;
  final VoidCallback onButtonPressed;
  final String buttonText;
  final bool isRemoveButton;
  final bool isButtonEnabled;

  const MenuItemDetailBottomBar({
    Key? key,
    required this.quantity,
    required this.onDecrementQuantity,
    required this.onIncrementQuantity,
    required this.onButtonPressed,
    required this.buttonText,
    this.isRemoveButton = false,
    this.isButtonEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !isRemoveButton && !isButtonEnabled;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: ColorApp.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _MenuDetailQuantitySelector(
              quantity: quantity,
              onDecrement: onDecrementQuantity,
              onIncrement: onIncrementQuantity,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isDisabled ? null : onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRemoveButton
                      ? ColorApp.redColor
                      : isDisabled
                          ? ColorApp.greyMedium
                          : ColorApp.primary,
                  foregroundColor: ColorApp.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                  shadowColor: ColorApp.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isRemoveButton)
                      SvgPicture.asset(
                        MediaRes.cartIcon,
                        width: 20,
                        height: 20,
                        color: ColorApp.white,
                      ),
                    if (!isRemoveButton) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDetailQuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _MenuDetailQuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: onDecrement,
              color: ColorApp.black,
              padding: EdgeInsets.zero,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorApp.black,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: onIncrement,
              color: ColorApp.black,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
