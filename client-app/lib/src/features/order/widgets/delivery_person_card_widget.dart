import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryPersonCard extends StatelessWidget {
  final DeliveryPerson person;
  final AppLocalizations localization;
  const DeliveryPersonCard({super.key, required this.person, required this.localization});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorApp.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF00695C),
            backgroundImage: const AssetImage('assets/images/delivery_icon.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.deliveryPerson,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (person.phoneNumber != null) ...[
                  GestureDetector(
                    onTap: () async {
                      final Uri phoneUri = Uri.parse('tel:${person.phoneNumber}');
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
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: ColorApp.primary,
                      child: Icon(Icons.phone, color: ColorApp.white, size: 20),
                    ),
                  )
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
