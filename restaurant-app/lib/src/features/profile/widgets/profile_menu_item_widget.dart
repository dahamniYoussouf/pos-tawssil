import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:restaurant_app/src/core/res/media_res.dart';

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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFF3F4F6),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              colorFilter: ColorFilter.mode(
                isDestructive ? Colors.red : const Color(0xFF374151),
                BlendMode.srcIn,
              ),
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}
