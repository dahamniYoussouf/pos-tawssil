import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:delivery_app/l10n/app_localizations.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String price;
  final String distance;
  final VoidCallback onActionTap;

  const NotificationCard({
    super.key,
    required this.title,
    required this.price,
    required this.distance,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              MediaRes.deliveryNotifyIcon,
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          // Info Section
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.gilmerBold.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      price,
                      style: AppTextStyles.gilmerBold.copyWith(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "•",
                      style: TextStyle(color: AppColors.grey, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: AppTextStyles.gilmerRegular.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Button
          ElevatedButton(
            onPressed: onActionTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(64, 36),
            ),
            child: Text(
              AppLocalizations.of(context)!.view,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
