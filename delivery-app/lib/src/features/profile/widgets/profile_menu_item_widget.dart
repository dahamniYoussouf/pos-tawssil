import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfileMenuItemWidget extends StatelessWidget {
  final String? icon;
  final IconData? iconData;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileMenuItemWidget({
    super.key,
    this.icon,
    this.iconData,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  }) : assert(icon != null || iconData != null,
            'Either icon or iconData must be provided');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            //hna space left to icon
            const SizedBox(width: 16),
            if (icon != null)
              SvgPicture.asset(
                icon!,
                colorFilter: ColorFilter.mode(
                  isDestructive ? Colors.red : const Color(0xFF374151),
                  BlendMode.srcIn,
                ),
                height: 24,
                width: 24,
              )
            else
              Icon(
                iconData,
                color: isDestructive ? Colors.red : const Color(0xFF374151),
                size: 24,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'Gilmer',
                  color: isDestructive ? Colors.red : const Color(0xFF111827),
                ),
              ),
            ),
            SvgPicture.asset(
              MediaRes.arrowRightIcon,
              colorFilter: ColorFilter.mode(
                isDestructive ? Colors.red : const Color(0xFF9CA3AF),
                BlendMode.srcIn,
              ),
              height: 18,
              width: 18,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
