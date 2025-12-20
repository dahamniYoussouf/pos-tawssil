import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import '../../auth/models/profile_model.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final ProfileModel profile;

  const ProfileHeaderWidget({
    super.key,
    required this.profile,
  });

  String get fullName => '${profile.firstName} ${profile.lastName}'.trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: ColorApp.greyLight,
            backgroundImage: profile.profileImageUrl != null &&
                    profile.profileImageUrl!.isNotEmpty
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            child: profile.profileImageUrl == null ||
                    profile.profileImageUrl!.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: ColorApp.grey,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isNotEmpty ? fullName : 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorApp.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactInfo(
            icon: Icons.phone,
            text: "(+213) ${profile.phoneNumber.replaceAll('213', '')}",
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: ColorApp.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: ColorApp.grey,
          ),
        ),
      ],
    );
  }
}
