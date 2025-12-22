import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfileMenuItemWidget extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileMenuItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              colorFilter: ColorFilter.mode(
                isDestructive ? ColorApp.redColor : ColorApp.textBlack,
                BlendMode.srcIn,
              ),
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isDestructive
                          ? ColorApp.redColor
                          : ColorApp.textBlack,
                    ),
              ),
            ),
            SvgPicture.asset(
              MediaRes.arrowRightIcon,
              colorFilter: ColorFilter.mode(
                isDestructive ? ColorApp.redColor : ColorApp.textBlack,
                BlendMode.srcIn,
              ),
              height: 24,
              width: 24,
            ),
          ],
        ),
      ),
    );
  }
}
