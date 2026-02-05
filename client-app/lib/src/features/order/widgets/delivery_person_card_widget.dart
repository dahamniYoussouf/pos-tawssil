import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryPersonCard extends StatelessWidget {
  final DeliveryPerson? person;
  final AppLocalizations localization;
  const DeliveryPersonCard(
      {super.key, required this.person, required this.localization});

  @override
  Widget build(BuildContext context) {
    if (person == null) {
      return _buildSearchingDriverCard(context);
    }
    return _buildAssignedDriverCard(context);
  }

  Widget _buildSearchingDriverCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorApp.greyBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorApp.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Image.asset(MediaRes.avatarPicture),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.searchingForDeliveryPerson,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      MediaRes.starImage,
                      height: 15,
                      width: 15,
                      color: ColorApp.greyIconColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '__',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorApp.greyIconColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'ID ______',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorApp.greyIconColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildIconButton(
            icon: MediaRes.messageIcon,
            onTap: null,
            isDisabled: true,
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: MediaRes.phoneIcon,
            onTap: null,
            isDisabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedDriverCard(BuildContext context) {
    final double rating = double.tryParse(person?.rating ?? '0.0') ?? 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorApp.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: ColorApp.white,
            child: Image.asset(MediaRes.avatarPicture),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Image.asset(
                      MediaRes.starImage,
                      height: 15,
                      width: 15,
                      color: ColorApp.greyIconColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : '—',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFFC107),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildIconButton(
            icon: MediaRes.messageIcon,
            onTap: () {},
            isDisabled: false,
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: MediaRes.phoneIcon,
            onTap: person?.phoneNumber != null
                ? () async {
                    final Uri phoneUri =
                        Uri.parse('tel:${person!.phoneNumber}');
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localization.error),
                          ),
                        );
                      }
                    }
                  }
                : null,
            isDisabled: person?.phoneNumber == null,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required String icon,
    required VoidCallback? onTap,
    required bool isDisabled,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ColorApp.greyBorder,
            width: 1.5,
          ),
        ),
        child: SvgPicture.asset(
          icon,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(
            isDisabled ? ColorApp.greyIconColor : ColorApp.textBlack,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
