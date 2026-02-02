import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:flutter/material.dart';

class ProfileStatsWidget extends StatelessWidget {
  final DriverModel driver;

  const ProfileStatsWidget({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Calculate years joined
    final yearsJoined =
        DateTime.now().difference(driver.createdAt).inDays ~/ 365;
    final rating = driver.rating ?? '5.0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          _buildStatCard(
            context,
            value: rating,
            label: l10n.rating,
            icon: Icons.star,
            iconColor: Colors.amber,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            value: driver.totalDeliveries.toString(),
            label: l10n.deliveries,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            value: yearsJoined.toString(),
            label: l10n.yearsJoined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    IconData? icon,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilmer',
                    color: Color(0xFF111827),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 4),
                  Icon(icon, color: iconColor, size: 24),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilmer',
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
