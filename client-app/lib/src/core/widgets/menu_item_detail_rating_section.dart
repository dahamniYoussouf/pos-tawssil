import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';

class MenuItemDetailRatingSection extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final VoidCallback? onSeeAllReviews;

  const MenuItemDetailRatingSection({
    Key? key,
    required this.rating,
    required this.reviewCount,
    this.onSeeAllReviews,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.star,
              color: ColorApp.premiumColor,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '$rating (${_formatReviewCount(reviewCount)})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: ColorApp.black,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onSeeAllReviews,
          child: Text(
            'See All Review',
            style: TextStyle(
              fontSize: 14,
              color: ColorApp.greyLight,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

