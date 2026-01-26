import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';

class MenuItemDetailItemHeader extends StatelessWidget {
  final String itemName;
  final String itemDescription;
  final double itemPrice;
  final double itemOldPrice;
  final bool hasDiscount;
  final double rating;
  final int reviewCount;

  const MenuItemDetailItemHeader({
    Key? key,
    required this.itemName,
    required this.itemDescription,
    required this.itemPrice,
    required this.itemOldPrice,
    required this.hasDiscount,
    required this.rating,
    required this.reviewCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: ColorApp.black,
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, color: ColorApp.premiumColor, size: 20),
                Text(
                  '${rating.toStringAsFixed(1)} (${reviewCount.toString()})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ColorApp.black,
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 2),
        if (itemDescription.isNotEmpty)
          Text(
            itemDescription,
            style: TextStyle(
              fontSize: 12,
              color: ColorApp.grey,
              height: 1.4,
            ),
          ),
        const SizedBox(height: 4),
        _MenuDetailPriceSection(
          itemPrice: itemPrice,
          itemOldPrice: itemOldPrice,
          hasDiscount: hasDiscount,
        ),
      ],
    );
  }
}

class _MenuDetailPriceSection extends StatelessWidget {
  final double itemPrice;
  final double itemOldPrice;
  final bool hasDiscount;

  const _MenuDetailPriceSection({
    required this.itemPrice,
    required this.itemOldPrice,
    required this.hasDiscount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasDiscount) ...[
          Text(
            '${itemOldPrice.toStringAsFixed(0)} DA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: ColorApp.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '${itemPrice.toStringAsFixed(0)} DA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: hasDiscount ? ColorApp.greenColor : ColorApp.black,
          ),
        ),
      ],
    );
  }
}
