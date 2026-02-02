import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:delivery_app/src/core/res/media_res.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final DriverModel driver;

  const ProfileHeaderWidget({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Gilmer',
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: const NetworkImage(
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=200',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          driver.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFamily: 'Gilmer',
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        if (driver.phoneNumber != null)
          _buildContactInfo(
            icon: Icons.phone,
            text: driver.phoneNumber!,
          ),
        const SizedBox(height: 4),
        if (driver.email != null)
          _buildContactInfo(
            icon: Icons.email_outlined,
            svgPath: MediaRes.mailIcon,
            text: driver.email!,
          ),
      ],
    );
  }

  Widget _buildContactInfo({
    IconData? icon,
    String? svgPath,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (svgPath != null)
          SvgPicture.asset(
            svgPath,
            height: 16,
            width: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFF6B7280),
              BlendMode.srcIn,
            ),
          )
        else if (icon != null)
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF6B7280),
          ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
